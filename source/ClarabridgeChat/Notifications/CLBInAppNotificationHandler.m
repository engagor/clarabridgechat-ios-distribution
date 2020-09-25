//
//  CLBInAppNotificationHandler.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBInAppNotificationHandler.h"
#import "CLBPushNotificationFilter.h"
#import "ClarabridgeChat+Private.h"
#import "CLBInAppNotificationWindow.h"
#import "CLBInAppNotificationViewController.h"
#import "CLBMessage+Private.h"
#import "CLBUtility.h"
#import "CLBImageLoader.h"
#import <UserNotifications/UserNotifications.h>
#import "CLBConversation+Private.h"

static const int HISTORY_SIZE = 5;

@interface CLBInAppNotificationHandler() < CLBInAppNotificationViewControllerDelegate >

@property CLBSettings* settings;
@property CLBInAppNotificationWindow* inAppNotificationWindow;
@property NSTimer* timer;
@property NSURLSessionDataTask* imageTask;
@property UNUserNotificationCenter* userNotificationCenter;
@property CLBConversation *conversation;

@end

@implementation CLBInAppNotificationHandler

-(instancetype)initWithSettings:(CLBSettings *)settings
         userNotificationCenter:(UNUserNotificationCenter *)userNotificationCenter
                   conversation:(CLBConversation *)conversation {
    self = [super init];
    if(self){
        _settings = settings;
        _userNotificationCenter = userNotificationCenter;
        _conversation = conversation;
    }
    return self;
}

-(void)dealloc {
    [self invalidateTimerAndHideWindow];
}

-(BOOL)shouldShowInAppNotification:(CLBMessage*)message conversation:(CLBConversation*)conversation {
    if ([ClarabridgeChat shouldSuppressInAppNotifs]){
        return NO;
    }

    BOOL applicationInForeground = [UIApplication sharedApplication].applicationState != UIApplicationStateBackground;
    BOOL conversationShown = [ClarabridgeChat isConversationShown];
    BOOL launchedFromNotification = [ClarabridgeChat wasLaunchedFromPushNotification];
    BOOL isForCurrentConversation = [conversation.conversationId isEqualToString:self.conversation.conversationId];

    return applicationInForeground && !launchedFromNotification && (!conversationShown || !isForCurrentConversation);
}

-(void)showInAppNotification:(CLBMessage *)message conversation:(CLBConversation*)conversation {
    if(CLBIsIOS10OrLater() && self.userNotificationCenter.delegate){
        [self.userNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if(settings.authorizationStatus == UNAuthorizationStatusAuthorized && settings.alertSetting == UNNotificationSettingEnabled) {
                [self showLocalNotification:message conversation:conversation];
            }else{
                [self showClarabridgeChatNotification:message conversation:conversation];
            }
        }];
    }else{
        [self showClarabridgeChatNotification:message conversation:conversation];
    }
}

-(void)showClarabridgeChatNotification:(CLBMessage*)message conversation:(CLBConversation*)conversation {
    [self.imageTask cancel];
    self.imageTask = nil;

    if(self.inAppNotificationWindow || self.timer){
        [self invalidateTimerAndHideWindow];
    }

    if(message.avatarUrl){
        NSString* urlWith404 = [NSString stringWithFormat:@"%@?d=404", message.avatarUrl];

        [[ClarabridgeChat avatarImageLoader] loadImageForUrl:urlWith404 withCompletion:^(UIImage *image) {
            CLBEnsureMainThread(^{
                [self showViewControllerWithMessage:message avatar:image conversation:conversation];
            });
        }];
    }else{
        // For unit tests
        [self showViewControllerWithMessage:message avatar:nil conversation:conversation];
    }
}

-(void)showLocalNotification:(CLBMessage *)message conversation:(CLBConversation*)conversation {
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.body = [self notificationContentBodyStringForMessage: message];
    content.categoryIdentifier = CLBUserNotificationReplyCategoryIdentifier;
    content.threadIdentifier = conversation.conversationId;
    content.sound = [UNNotificationSound defaultSound];

    NSUInteger index = [conversation.messages indexOfObject:message];

    NSMutableArray* history = [NSMutableArray array];

    NSUInteger historyLength = MIN(HISTORY_SIZE, index);

    [[conversation.messages subarrayWithRange:NSMakeRange(index - historyLength, historyLength)] enumerateObjectsUsingBlock:^(CLBMessage*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [history addObject:@{
                             @"text": obj.text ?: @"",
                             @"role": obj.role,
                             @"avatarUrl": obj.avatarUrl ?: @""
                             }];
    }];

    content.userInfo = @{
                         CLBPushNotificationIdentifier: @YES,
                         @"avatarUrl": message.avatarUrl ?: @"",
                         @"history": history,
                         @"message": [message serialize][@"message"],
                         @"conversationId": conversation.conversationId
                         };

    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:message.messageId content:content trigger:nil];

    [self.userNotificationCenter addNotificationRequest:request withCompletionHandler:nil];
}

-(NSString *)notificationContentBodyStringForMessage:(CLBMessage *)message {
    NSString *text = message.text;
    if(!text && message.actions.firstObject) {
        CLBMessageAction *action = message.actions.firstObject;
        text = action.text;
    }
    if(!text && message.mediaUrl && message.mediaUrl.length > 0) {
        text = [[message.mediaUrl componentsSeparatedByString:@"/"] lastObject];
    }
    if(!text) {
        text = @"";
    }

    if(message.displayName && message.displayName.length > 0){
        return [NSString stringWithFormat:@"%@: %@", message.displayName, text];
    }
    return text;
}

-(void)showViewControllerWithMessage:(CLBMessage*)message avatar:(UIImage*)image conversation:(CLBConversation*)conversation {
    CLBEnsureMainThread(^{
        self.inAppNotificationWindow = [[CLBInAppNotificationWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

        CLBInAppNotificationViewController* vc = [[CLBInAppNotificationViewController alloc] initWithMessage:message avatar:image conversation:conversation];
        vc.delegate = self;

        self.inAppNotificationWindow.rootViewController = vc;

        if(self.settings.notificationDisplayTime > 0){
            self.timer = [NSTimer scheduledTimerWithTimeInterval:self.settings.notificationDisplayTime target:self selector:@selector(timeOut) userInfo:nil repeats:NO];
        }

        self.inAppNotificationWindow.hidden = NO;
        self.inAppNotificationWindow.windowLevel = UIWindowLevelAlert;
    });
}

-(void)timeOut {
    CLBInAppNotificationViewController* viewController = (CLBInAppNotificationViewController*)self.inAppNotificationWindow.rootViewController;

    CLBEnsureMainThread(^{
        [viewController slideUpWithCompletion:^{
            [self removeInAppNotificationWindow];
        }];
    });
}

-(void)removeInAppNotificationWindow {
    CLBEnsureMainThread(^{
        self.inAppNotificationWindow.hidden = YES;
        self.inAppNotificationWindow = nil;
    });
}

-(void)invalidateTimerAndHideWindow {
    CLBEnsureMainThread(^{
        [self.timer invalidate];
        self.timer = nil;
        [self removeInAppNotificationWindow];
    });
}

#pragma mark - CLBInAppNotificationViewControllerDelegate

-(void)notificationViewControllerDidSelectNotification:(CLBInAppNotificationViewController *)viewController {
    [self invalidateTimerAndHideWindow];

    NSDictionary *info = @{
                           @"message": [viewController.message serialize],
                           @"conversationId": viewController.conversation.conversationId
                           };

    [ClarabridgeChat showConversation:viewController.conversation withAction:CLBActionInAppNotificationTapped info:info];
}

-(void)notificationViewControllerDidDismissNotification:(CLBInAppNotificationViewController *)viewController {
    [self invalidateTimerAndHideWindow];
}

@end
