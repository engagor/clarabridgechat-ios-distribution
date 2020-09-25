//
//  CLBConversationFetchScheduler.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBConversationFetchScheduler.h"
#import "CLBConversation+Private.h"
#import "CLBConversationMonitor.h"
#import "CLBRemoteObjectSynchronizer.h"
#import "CLBInAppNotificationHandler.h"
#import "ClarabridgeChat+Private.h"
#import "CLBUserSynchronizer.h"
#import "CLBDependencyManager.h"
#import "CLBMessage+Private.h"
#import "CLBRemoteResponse.h"
#import "CLBUtility.h"
#import "CLBUser+Private.h"
#import "CLBApiClient.h"
#import "CLBAuthorInfo.h"

static NSString* const kUserDefaultsKey = @"CLBConversationFetchSchedulerMessagesCountKey";
static NSString* const kMessagesKey = @"messages";

@interface CLBConversationFetchScheduler()

@property CLBConversationMonitor *monitor;
@property BOOL fetchingPreviousMessages;
@end

@implementation CLBConversationFetchScheduler

- (instancetype)initWithConversation:(CLBConversation*)conversation
                 conversationMonitor:(CLBConversationMonitor *)conversationMonitor
                        notifHandler:(CLBInAppNotificationHandler*)notifHandler
                        synchronizer:(CLBRemoteObjectSynchronizer*)synchronizer {
    self = [super init];
    if(self){
        _notifHandler = notifHandler;
        _synchronizer = synchronizer;
        _fetchingPreviousMessages = NO;
        _conversation = conversation;
        _monitor = conversationMonitor;

        [conversation addObserver:self forKeyPath:kMessagesKey options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessagesChanged:) name:CLBConversationDidReceiveMessagesNotification object:conversation];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPreviousMessages:) name:CLBConversationDidRequestPreviousMessagesNotification object:conversation];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typingStarted:) name:CLBConversationTypingDidStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typingStopped:) name:CLBConversationTypingDidStopNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markAsReadOnServer:) name:CLBConversationDidMarkAllAsReadNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.conversation removeObserver:self forKeyPath:kMessagesKey];
}

- (void)markAsReadOnServer:(NSNotification *)notification {
    CLBConversation *conversation = (CLBConversation *)notification.object;
    if (conversation != nil) {
        [self sendConversationActivity:@"conversation:read" toConversation:conversation];
    }
}

- (void)typingStarted:(NSNotification *)notification {
    CLBConversation *conversation = (CLBConversation *)notification.object;
    if (conversation != nil) {
        [self sendConversationActivity:@"typing:start" toConversation:conversation];
    }
}

- (void)typingStopped:(NSNotification *)notification {
    CLBConversation *conversation = (CLBConversation *)notification.object;
    if (conversation != nil) {
        [self sendConversationActivity:@"typing:stop" toConversation:conversation];
    }
}

- (void)sendConversationActivity:(NSString*)type toConversation:(CLBConversation *)conversation {
    if ([self canSendActivity]){
        return;
    }
    
    if (!self.conversation.user.settings.typingEnabled && [self activityTypeIsTyping:type]) {
        return;
    }

    NSString* url = [NSString stringWithFormat:@"/v2/apps/%@/conversations/%@/activity", conversation.appId, conversation.conversationId];
    [self.synchronizer.apiClient requestWithMethod:@"POST"
                                               url:url
                                        parameters:[self parametersForType:type user:conversation.user]
                                        completion:nil];
}


- (void)loadPreviousMessages:(NSNotification *)notification {
    if (!self.conversation.conversationStarted || !self.conversation.hasPreviousMessages || self.fetchingPreviousMessages) {
        return;
    }

    self.fetchingPreviousMessages = YES;

    CLBMessage *oldestMessage = [self.conversation.messages firstObject];
    NSString *oldestMessageDate = [NSString stringWithFormat:@"%f", oldestMessage.date.timeIntervalSince1970];

    [self.synchronizer.apiClient GET:[self.conversation messagesRemotePath]
                          parameters:@{@"before": oldestMessageDate}
                          completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        if(error){
            CLBDebug(@"GET for previous messages failed for conversation: %@\nError: %@", self.conversation, error);
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
            userInfo[@"error"] = error;
            [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationDidReceivePreviousMessagesNotification object:self.conversation userInfo:userInfo];
        } else{
            CLBDebug(@"GET for previous messages succeeded for conversation: %@\nResponse: %@", self.conversation, responseObject);
            [self.conversation deserialize:responseObject];
        }
        self.fetchingPreviousMessages = NO;
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([change[NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeInsertion){
        NSArray* insertions = change[NSKeyValueChangeNewKey];
        if(insertions.count == 1){
            [self onMessageInserted:insertions[0]];
        }
    }
}

- (void)onMessageInserted:(CLBMessage*)newMessage {
    if(!newMessage.isFromCurrentUser || newMessage.uploadStatus != CLBMessageUploadStatusUnsent || [newMessage.type isEqualToString:CLBMessageTypeFile]){
        return;
    }
    if (!self.monitor.isConnected) {
        [self.monitor connectImmediately];
    }

    if (self.conversation.conversationId == nil) {
        [self startConversationAndSendMessage:newMessage];
        return;
    }

    [self sendMessage:newMessage];
}

- (void)startConversationAndSendMessage:(CLBMessage *)newMessage {
    [ClarabridgeChat startConversationWithIntent:@"message:appUser" completionHandler:^(NSError *error, NSDictionary *userInfo) {
        if (!error) {
            [self sendMessage:newMessage];
        } else {
            CLBEnsureMainThread(^{
                newMessage.uploadStatus = CLBMessageUploadStatusFailed;
                [[NSNotificationCenter defaultCenter] postNotificationName:CLBMessageUploadFailedNotification object:newMessage];
            });

            [self.conversation saveToDisk];
        }
    }];
}

- (void)sendNotificationReplyForMessage:(CLBMessage *)message conversationId:(NSString *)conversationId {
    __block CLBConversation *conversation = [[CLBConversation alloc] init];
    conversation.appId = self.conversation.appId;
    conversation.user = self.conversation.user;
    conversation.conversationId = conversationId;
    message.conversation = conversation;
    
    [[ClarabridgeChat dependencyManager].userSynchronizer scheduleImmediately];
    
    [self.synchronizer synchronize:message completion:^(CLBRemoteResponse* response) {
        if(response.error){
            message.uploadStatus = CLBMessageUploadStatusFailed;
            [[NSNotificationCenter defaultCenter] postNotificationName:CLBMessageUploadFailedNotification object:message];
        }else{
            message.uploadStatus = CLBMessageUploadStatusSent;
            [[NSNotificationCenter defaultCenter] postNotificationName:CLBMessageUploadCompletedNotification object:message];
        }
        
        conversation = nil;
    }];
}

- (void)sendMessage:(CLBMessage *)message {
    NSUInteger currentCount = self.conversation.messageCount;

    // New user message added, force sync
    [[ClarabridgeChat dependencyManager].userSynchronizer scheduleImmediately];

    // Upload it
    [self.synchronizer synchronize:message completion:^(CLBRemoteResponse* response) {
        message.uploadStatus = response.error ? CLBMessageUploadStatusFailed : CLBMessageUploadStatusSent;
        NSString *notification = response.error ? CLBMessageUploadFailedNotification : CLBMessageUploadCompletedNotification;

        [[NSNotificationCenter defaultCenter] postNotificationName:notification object:message];

        // If conversation returns with more messages, faye failed somehow. Reconnect manually
        if(currentCount < self.conversation.messageCount && [self.monitor isConnected]) {
            [self.monitor reconnect];
        }

        [self.conversation saveToDisk];
    }];
}

- (void)onMessagesChanged:(NSNotification*)notification {
    NSArray* messages = notification.userInfo[CLBConversationNewMessagesKey];

    if([messages lastObject]){
        [self showInAppNotificationForMessage:[messages lastObject] conversation:self.conversation];
    }
}

- (void)showInAppNotificationForMessage:(CLBMessage*)message conversation:(CLBConversation*)conversation {
    if (![self.notifHandler shouldShowInAppNotification:message conversation:conversation]) {
        return;
    }

    // Use self.conversation to get the delegate, temporary conversation instances will not have a delegate
    id<CLBConversationDelegate> delegate = self.conversation.delegate;

    if([delegate respondsToSelector:@selector(conversation:shouldShowInAppNotificationForMessage:)]) {
        CLBEnsureMainThread(^{
            CLBMessage *notificationMessage = [message copy];
            if([delegate conversation:conversation shouldShowInAppNotificationForMessage:notificationMessage]){
                [self.notifHandler showInAppNotification:notificationMessage conversation:conversation];
            }
        });
    }else{
        [self.notifHandler showInAppNotification:message conversation:conversation];
    }
}

#pragma mark - Helpers

- (BOOL)activityTypeIsTyping:(NSString *)type {
    return ([CLBConversationActivityTypeTypingStart isEqualToString:type] || [CLBConversationActivityTypeTypingStop isEqualToString:type]);
}

- (BOOL)canSendActivity {
    return !self.conversation.conversationStarted || !self.conversation.user.userId || !self.conversation.conversationId;
}

- (NSDictionary *)parametersForType:(NSString *)type user: (CLBUser *)user {
    NSDictionary *parameters = @{ @"activity": @{ @"type": type },
                                  @"author": [CLBAuthorInfo authorFieldForUser:user]
    };
    return parameters;
}

@end
