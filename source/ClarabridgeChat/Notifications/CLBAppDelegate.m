//
//  CLBAppDelegate.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBAppDelegate.h"
#import "ClarabridgeChat+Private.h"
#import "CLBInAppNotificationViewController.h"
#import "CLBMessage.h"
#import "CLBInAppNotificationWindow.h"
#import "CLBInAppNotificationHandler.h"
#import "CLBPushNotificationFilter.h"
#import "CLBConfig.h"
#import "CLBDependencyManager.h"
#import "CLBDependencyManager+Private.h"
#import "CLBConfigFetchScheduler.h"
#import "CLBUser+Private.h"
#import "CLBUserSynchronizer.h"
#import "CLBConversationMonitor.h"
#import "CLBConversation+Private.h"
#import "CLBUtility.h"
#import "CLBRemoteResponse.h"
#import "CLBLocalization.h"
#import "CLBConversationFetchScheduler.h"

@interface CLBAppDelegate()

@property BOOL registered;
@property(weak) CLBDependencyManager* dependencyManager;
@property CLBMessage* pendingMessage;
@property NSString* conversationId;
@property void (^completionHandler)(void);

@end

@implementation CLBAppDelegate

-(instancetype)init {
    return [self initWithPushFilter:nil dependencyManager:nil];
}

- (instancetype)initWithPushFilter:(CLBPushNotificationFilter *)pushFilter dependencyManager:(CLBDependencyManager *)dependencyManager {
    self = [super init];
    if (self) {
        _pushFilter = pushFilter;
        _dependencyManager = dependencyManager;
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleNotification:(NSDictionary*)userInfo {
    if(![self.pushFilter isClarabridgeChatNotification:userInfo]){
        return;
    }

    NSNumber* unreadCount = userInfo[@"aps"][@"badge"];
    if(unreadCount != nil){
        [UIApplication sharedApplication].applicationIconBadgeNumber = [unreadCount integerValue];
    }

    self.dependencyManager.userSynchronizer.user.conversationStarted = YES;

    UIApplicationState applicationState = [UIApplication sharedApplication].applicationState;

    if(applicationState == UIApplicationStateActive || (CLBIsIOS10OrLater() && applicationState == UIApplicationStateInactive)){
        [self.dependencyManager.conversationMonitor connectImmediately];
    }else{
        [ClarabridgeChat showConversationWithAction:CLBActionPushNotificationTapped info:userInfo];
    }
}

-(void)sendPendingMessage {
    if (!self.pendingMessage) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageUploadCompleted) name:CLBMessageUploadCompletedNotification object:self.pendingMessage];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageUploadFailed) name:CLBMessageUploadFailedNotification object:self.pendingMessage];

    CLBMessage* message = self.pendingMessage;
    self.pendingMessage = nil;

    [self.dependencyManager handleSendPendingMessage:message conversationId:self.conversationId];
    self.conversationId = nil;
}

-(void)messageUploadCompleted {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CLBInitializationDidFailNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CLBInitializationDidCompleteNotification object:nil];
    
    self.completionHandler();
}

-(void)messageUploadFailed {
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    
    content.title = [CLBLocalization localizedStringForKey:@"Error"];
    content.body = [CLBLocalization localizedStringForKey:@"Message not delivered. Please try again later."];;
    content.sound = [UNNotificationSound defaultSound];
    content.userInfo = @{
                         CLBPushNotificationIdentifier: @YES
                         };
    
    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString] content:content trigger:nil];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
    
    self.pendingMessage = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CLBInitializationDidFailNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CLBInitializationDidCompleteNotification object:nil];
    
    self.completionHandler();
}

-(void)handleUserNotificationActionWithIdentifier:(NSString *)identifier withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler {
    [self handleUserNotificationActionWithIdentifier:identifier forRemoteNotification:nil withResponseInfo:responseInfo completionHandler:completionHandler];
}

-(void)handleUserNotificationActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler {
    self.conversationId = userInfo[@"conversationId"];
    
    NSString* replyText = responseInfo[UIUserNotificationActionResponseTypedTextKey];
    
    [self handleUserNotificationActionWithIdentifier:identifier withText:replyText completionHandler:completionHandler];
}

-(void)handleUserNotificationActionWithIdentifier:(NSString *)identifier withText:(NSString *)text completionHandler:(void (^)(void))completionHandler {
    self.completionHandler = completionHandler;

    BOOL isClarabridgeChatReplyAction = [identifier isEqualToString:CLBUserNotificationReplyActionIdentifier];
    BOOL hasText = text && [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0;

    if(!isClarabridgeChatReplyAction || !hasText){
        self.completionHandler();
        return;
    }

    self.pendingMessage = [[CLBMessage alloc] initWithText:text];

    CLBConfigFetchScheduler* configScheduler = self.dependencyManager.configFetchScheduler;

    if (configScheduler.config.validityStatus == CLBAppStatusValid) {
        [self sendPendingMessage];
    } else if (configScheduler.config.validityStatus == CLBAppStatusInvalid) {
        [self messageUploadFailed];
    } else {
        if (!self.registered) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initializationFailed) name:CLBInitializationDidFailNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initializationSucceeded) name:CLBInitializationDidCompleteNotification object:nil];
            self.registered = YES;
        }
        
        if (!configScheduler.isExecuting) {
            NSString* deviceIdentifier = CLBGetUniqueDeviceIdentifier();
            
            if (deviceIdentifier) {
                [ClarabridgeChat fetchConfig];
            } else {
                // Client ID can't be fetched from persistence, the message cannot be sent
                // Notify the user of the failure
                [self messageUploadFailed];
            }
        }
    }
}

-(void)initializationSucceeded {
    [self sendPendingMessage];
}

-(void)initializationFailed {
    [self messageUploadFailed];
}

#pragma mark - UIApplicationDelegate

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if(self.dependencyManager.config.pushEnabled){
        [ClarabridgeChat setPushToken:deviceToken];
    }
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if(self.dependencyManager.config.pushEnabled){
        NSLog(@"<CLARABRIDGECHAT::ERROR> Push notifications are enabled, but registration FAILED! Please ensure your provisioning profile and push certificate are configured correctly. Error : %@", error);
    }
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self handleNotification:userInfo];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void(^)(void))completionHandler {
    [self handleUserNotificationActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:completionHandler];
}

#pragma mark - UIUserNotificationCenterDelegate

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    if(![self.pushFilter isClarabridgeChatNotification:notification.request.content.userInfo]){
        if(self.otherNotificationCenterDelegate && [self.otherNotificationCenterDelegate respondsToSelector:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)]){
            [self.otherNotificationCenterDelegate userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
        }else{
            completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge);
        }
        return;
    }

    if([self.pushFilter isRemoteNotification:notification]){
        self.dependencyManager.userSynchronizer.user.conversationStarted = YES;
        
        if (self.dependencyManager.config.validityStatus == CLBAppStatusValid && !self.dependencyManager.conversationMonitor.isConnected) {
            [self.dependencyManager.conversationMonitor connectImmediately];
        }

        completionHandler(UNNotificationPresentationOptionBadge);
    }else{
        completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
    }
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    if(![self.pushFilter isClarabridgeChatNotification:response.notification.request.content.userInfo]){
        if(self.otherNotificationCenterDelegate && [self.otherNotificationCenterDelegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]){
            [self.otherNotificationCenterDelegate userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
        }else{
            completionHandler();
        }
        return;
    }

    if([response.actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]){
        CLBAction action = ([self.pushFilter isRemoteNotification:response.notification]) ? CLBActionPushNotificationTapped : CLBActionInAppNotificationTapped;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ClarabridgeChat showConversationWithAction:action info: response.notification.request.content.userInfo];
            completionHandler();
        });
    }else if([response isKindOfClass:[UNTextInputNotificationResponse class]] && [response.actionIdentifier isEqualToString:CLBUserNotificationReplyActionIdentifier]){
        UNTextInputNotificationResponse* textResponse = (UNTextInputNotificationResponse*)response;
        self.conversationId = response.notification.request.content.userInfo[@"conversationId"];

        [self handleUserNotificationActionWithIdentifier:textResponse.actionIdentifier withText:textResponse.userText completionHandler:completionHandler];
    }else{
        completionHandler();
    }
}

@end
