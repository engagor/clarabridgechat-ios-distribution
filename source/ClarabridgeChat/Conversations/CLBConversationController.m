//
//  CLBConversationController.m
//  ClarabridgeChat
//
//  Created by Shona Nunez on 22/11/2019.
//  Copyright © 2019 Smooch Technologies. All rights reserved.
//

#import "CLBConversationController.h"
#import "CLBConversation.h"
#import "CLBConversation+Private.h"
#import "CLBConversationActivity+Private.h"
#import "CLBConversationList.h"
#import "CLBConfig.h"
#import "CLBSettings.h"
#import "CLBUtilitySettings.h"
#import "CLBLocalization.h"
#import "CLBMessageAction+Private.h"
#import "CLBMessage.h"
#import "CLBMessage+Private.h"
#import "CLBConversationFetchScheduler.h"
#import "CLBRemoteObjectSynchronizerProtocol.h"
#import "CLBRemoteObjectSynchronizer.h"
#import "CLBConversationStorageManager.h"
#import "CLBEventTypeFactory.h"
#import "CLBConversationFetchSchedulerProtocol.h"
#import "CLBConversationSynchronizer.h"
#import "CLBUser.h"
#import "CLBParticipant.h"

NSString *const CLBEventsKey = @"events";
NSString *const CLBTypeKey = @"type";
NSString *const CLBMessageKey = @"message";
NSString *const CLBAuthorIdKey = @"authorId";
NSString *const CLBReceivedKey = @"received";
NSString *const CLBLastReadKey = @"lastRead";

@interface CLBConversationController()

@property CLBConversationFetchScheduler *conversationFetchScheduler;
@property CLBRemoteObjectSynchronizer *synchronizer;
@property CLBConfig *config;
@property CLBSettings *settings;
@property id<CLBUtilitySettings> utilitySettings;
@property CLBConversationStorageManager *storage;
@property NSString *currentConversationId;
@property CLBConversation *conversation;
@property CLBUser *user;

@end

@implementation CLBConversationController

- (instancetype)initWithFetchScheduler:(id<CLBConversationFetchSchedulerProtocol>)conversationFetchScheduler
                          synchronizer:(id<CLBRemoteObjectSynchronizerProtocol>)synchronizer
                                config:(CLBConfig *)config
                              settings:(CLBSettings *)settings
                       utilitySettings:(id<CLBUtilitySettings>)utilitySettings
                               storage:(CLBConversationStorageManager *)storage
                          conversation:(CLBConversation *)conversation
                                  user:(CLBUser *)user {
    self = [super init];

    if (self) {
        self.conversationFetchScheduler = conversationFetchScheduler;
        self.synchronizer = synchronizer;
        self.config = config;
        self.settings = settings;
        self.utilitySettings = utilitySettings;
        self.storage = storage;
        self.conversation = conversation;
        self.user = user;
    }

    return self;
}

#pragma mark - Outgoing Conversation Helper Methods
- (BOOL)isAppValid {
    return self.config.validityStatus == CLBAppStatusValid;
}

- (BOOL)shouldWorkOffline {
    return self.settings.allowOfflineUsage && self.config.validityStatus != CLBAppStatusInvalid;
}

- (BOOL)canSendMessage {
    return !(![self shouldWorkOffline] && (![self.utilitySettings isNetworkAvailable] || ![self isAppValid]));
}

- (BOOL)canSendMessage:(NSString *)message {
    BOOL hasContent = [[message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0;
    return hasContent && [self canSendMessage];
}

- (NSString * _Nullable)checkFileSizeForError:(long long)fileSize {
    if (fileSize > [self.utilitySettings messageFileSizeLimit]) {
        NSString *readableMaxSize = [NSByteCountFormatter stringFromByteCount:CLBMessageFileSizeLimit
                                                                   countStyle:NSByteCountFormatterCountStyleFile];
        NSString *errorMessage = [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"Max file size limit exceeded %@."], readableMaxSize];

        return errorMessage;
    }

    return nil;
}

#pragma mark - CLBConversationViewControllerDelegate

- (void)conversationViewController:(CLBConversationViewController *)controller didBeginTypingInConversation:(NSString *)conversationId {
    [[self conversation:conversationId] startTyping];
}

- (void)conversationViewController:(CLBConversationViewController *)controller didFinishTypingInConversation:(NSString *)conversationId {
    [[self conversation:conversationId] stopTyping];
}

- (void)conversationViewController:(CLBConversationViewController *)controller didMarkAllAsReadInConversation:(NSString *)conversationId {
    [[self conversation:conversationId] markAllAsRead];
}

- (BOOL)conversationViewController:(CLBConversationViewController *)controller shouldLoadPreviousMessagesInConversation:(NSString *)conversationId {
    return [self conversation:conversationId].hasPreviousMessages;
}

- (void)conversationViewController:(CLBConversationViewController *)controller didLoadPreviousMessagesInConversation:(NSString *)conversationId {
    [[self conversation:conversationId] loadPreviousMessages];
}

- (void)conversationViewController:(CLBConversationViewController *)controller didRetryMessage:(CLBMessage *)message inConversation:(NSString *)conversationId {
    if (conversationId == nil) {
        if (self.conversation && self.conversation.conversationId == nil) {
            [self.conversation retryMessage:message];
        }
    } else {
        [[self conversation:conversationId] retryMessage:message];
    }
}

- (BOOL)conversationViewControllerCanCheckIsAppValid:(CLBConversationViewController *)controller {
    return [self isAppValid];
}

- (BOOL)conversationViewControllerShouldWorkOffline:(CLBConversationViewController *)controller {
    return [self shouldWorkOffline];
}

- (BOOL)conversationViewControllerCanSendMessage:(CLBConversationViewController *)controller {
    return [self canSendMessage];
}

- (BOOL)conversationViewController:(CLBConversationViewController *)controller canSendMessage:(NSString *)messageText {
    return [self canSendMessage:messageText];
}

- (void)conversationViewController:(CLBConversationViewController *)controller didSendMessage:(CLBMessage *)message inConversation:(NSString *)conversationId {
    message.isFromCurrentUser = YES;
    if (conversationId == nil) {
        if (self.conversation && self.conversation.conversationId == nil) {
            [self.conversation sendMessage:message];
        }
    } else {
        [[self conversation:conversationId] sendMessage:message];
    }

}

- (void)conversationViewController:(CLBConversationViewController *)controller didSendMessageText:(NSString *)text inConversation:(NSString *)conversationId {
    CLBMessage* message = [[CLBMessage alloc] initWithText:[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    message.isFromCurrentUser = YES;
    if (conversationId == nil) {
        if (self.conversation && self.conversation.conversationId == nil) {
            [self.conversation sendMessage:message];
        }
    } else {
        [[self conversation:conversationId] sendMessage:message];
    }
}

- (void)conversationViewController:(CLBConversationViewController *)controller didSendMessageFromAction:(CLBMessageAction *)action inConversation:(NSString *)conversationId {
    CLBMessage *message = [[CLBMessage alloc] initWithText:action.text payload:action.payload metadata:action.metadata];
    message.isFromCurrentUser = YES;
    if (conversationId == nil) {
        if (self.conversation && self.conversation.conversationId == nil) {
            [self.conversation sendMessage:message];
        }
    } else {
        [[self conversation:conversationId] sendMessage:message];
    }
}

- (void)conversationViewController:(CLBConversationViewController *)controller didSendImage:(UIImage *)image inConversation:(NSString *)conversationId {
    if (conversationId == nil) {
        if (self.conversation && self.conversation.conversationId == nil) {
            [self.conversation sendImage:image withProgress:nil completion:nil];
        }
    } else {
        [[self conversation:conversationId] sendImage:image withProgress:nil completion:nil];
    }
}

- (NSString * _Nullable)conversationViewController:(CLBConversationViewController *)controller didCheckForErrorForFileURL:(NSURL *)fileLocation inConversation:(NSString *)conversationId {
    return [self checkFileSizeForError:[self.utilitySettings sizeForFile:fileLocation]];
}

- (void)conversationViewController:(CLBConversationViewController *)controller didSendFileURL:(NSURL *)fileLocation inConversation:(NSString *)conversationId {
    NSString *encodedFilename = [fileLocation.lastPathComponent stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
    NSURL *tempURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@%@", NSTemporaryDirectory(), encodedFilename]];
    [[NSFileManager defaultManager] copyItemAtURL:fileLocation toURL:tempURL error:nil];

    [[self conversation:conversationId] sendFile:tempURL withProgress:nil completion:nil];
}

- (CLBConversation *)conversation:(NSString *)conversationId {
    CLBConversation *currentConversation = [self.storage readConversation:conversationId];

    if (currentConversation == nil && self.conversation) {
        currentConversation = self.conversation;
    }

    return currentConversation;
}

- (void)conversationViewController:(CLBConversationViewController *)controller didSendPostback:(CLBMessageAction *)action inConversation:(NSString *)conversationId completion:(void (^)(NSError * _Nullable))completion {
    if([action.uiState isEqualToString:CLBMessageActionUIStateProcessing]){
        completion(nil);
        return;
    }

    [[self conversation:conversationId] postback:action completion:^(NSError *error) {
        completion(error);
    }];
}

- (BOOL)isPushEnabled {
    return self.config.pushEnabled;
}

//MARK: - CLBConversationMonitorListener
- (void)onMessageReceived:(NSDictionary *)messageData fromChannel:(NSString *)channel {
    NSArray *events = messageData[CLBEventsKey];

    CLBEventTypeFactory *factory = [[CLBEventTypeFactory alloc] initWithConversation:self.conversation
                                                                     utilitySettings:self.utilitySettings];
    factory.delegate = self;

    for (NSDictionary *event in events) {
        CLBEventType type = [factory eventTypeFromString:event[CLBTypeKey]];
        [factory handleEventType:type withEvent:event];
    }
}

- (void)onConnectionRefresh {
    [self updateConversationList];
}

- (void)updateConversationList {
    CLBConversationSynchronizer *conversationSynchronizer = [[CLBConversationSynchronizer alloc] initWithUser:self.user
                                                                                                 synchronizer:self.synchronizer
                                                                                                     settings:self.settings
                                                                                              utilitySettings:self.utilitySettings];

    [conversationSynchronizer getConversationListWithCompletionHandler:^(NSError *error, NSDictionary *responseObject) {
        if (error != nil || responseObject == nil) {
            return;
        }

        CLBConversationList *conversationList = [[CLBConversationList alloc] initWithAppId:self.settings.appId user:self.user];
        [conversationList deserialize:responseObject];

        if (conversationList == nil) {
            return;
        }

        if (self.conversation.delegate && [self.conversation.delegate respondsToSelector:@selector(conversationListDidRefresh:)]) {
            [self.conversation.delegate conversationListDidRefresh:conversationList.conversations];
        }

        [self.storage clearStorage];
        [self.storage storeConversationList:conversationList];

        if (self.conversation.conversationId != nil) {
            [self.synchronizer fetch:self.conversation completion:nil];
        }
    }];
}

- (void)getConversationById:(NSString *)conversationId withCompletionHandler:(void (^)(NSError * _Nullable, CLBConversation * _Nullable))handler {
    CLBConversationSynchronizer *conversationSynchronizer = [[CLBConversationSynchronizer alloc] initWithUser:self.user
                                                                                                 synchronizer:self.synchronizer
                                                                                                     settings:self.settings
                                                                                              utilitySettings:self.utilitySettings];

    [conversationSynchronizer getConversationById:conversationId withCompletionHandler:^(NSError *error, NSDictionary *responseObject) {
        if (error != nil || responseObject == nil) {
            handler(error, nil);
        }

        CLBConversation *conversation = [[CLBConversation alloc] initWithAppId:self.settings.appId user:self.user];
        [conversation deserialize:responseObject];

        [self.storage storeConversation:conversation];
        handler(nil, conversation);
    }];
}

//MARK: - CLBEventTypeFactoryDelegate

- (void)conversationRemoved:(NSString *)conversationId {
    [self.storage removeConversation:conversationId];
}

- (CLBConversation *)conversationById:(NSString *)conversationId {
    return [self.storage readConversation:conversationId];
}

- (BOOL)messagesAreInSyncInStorageForConversationId:(NSString *)conversationId {
    return [self.storage messagesAreInSyncInStorageForConversationId:conversationId];
}

- (void)currentConversationNeedsRefresh:(CLBConversation *)conversation {
    [self.synchronizer fetch:conversation completion:nil];
}

- (void)currentConversationListNeedsRefresh {
    [self updateConversationList];
}

- (void)showInAppNotificationForMessage:(CLBMessage *)message conversationId:(NSString *)conversationId {
    CLBConversation *otherConversation = [self.storage readConversation:conversationId];

    if (otherConversation != nil) {
        [self appendMessage:message toConversation:otherConversation];
        [self.conversationFetchScheduler showInAppNotificationForMessage:message conversation:otherConversation];
    }
}

- (void)appendMessage:(CLBMessage *)message toConversation:(CLBConversation *)conversation {
    NSMutableArray *messages = [conversation.messages mutableCopy];
    [messages addObject:message];
    conversation.messages = messages;
    [self.storage storeConversation:conversation];
}

- (void)updateParticipantListForConversationId:(NSString *)conversationId
                                     withEvent:(NSDictionary *)event
                          isActiveConversation:(BOOL)isForActiveConversation {
    CLBConversation *conversation = [self conversation:conversationId];

    if (conversation == nil) {
        return;
    }

    for (CLBParticipant *participant in conversation.participants) {
        BOOL isAuthor = [participant.appUserId isEqualToString:event[CLBMessageKey][CLBAuthorIdKey]];
        BOOL isCurrentUser = [participant.appUserId isEqualToString:[CLBUser currentUser].appUserId];

        if (isAuthor || (isCurrentUser && isForActiveConversation)) {
            participant.lastRead = [NSDate dateWithTimeIntervalSince1970:[event[CLBMessageKey][CLBReceivedKey] doubleValue]];
        } else {
            participant.unreadCount = [NSNumber numberWithInt:([participant.unreadCount intValue] + 1)];
        }
    }

    [self.storage storeConversation:conversation];
    CLBConversationList *conversationList = [self.storage getConversationList];

    if (self.conversation.delegate && [self.conversation.delegate respondsToSelector:@selector(conversationListDidRefresh:)]) {
        [self.conversation.delegate conversationListDidRefresh:conversationList.conversations];
    }
}

-(void)handleActivity:(CLBConversationActivity *)activity forConversation:(CLBConversation *)conversation {
    if ([CLBConversationActivityTypeConversationRead isEqualToString:activity.type]) {
        conversation.appMakerLastRead = activity.appMakerLastRead;

        for (CLBParticipant *participant in conversation.participants) {
            if ([participant.appUserId isEqualToString:activity.appUserId]) {
                participant.lastRead = [NSDate dateWithTimeIntervalSince1970:[activity.data[CLBLastReadKey] doubleValue]];
                participant.unreadCount = [NSNumber numberWithInt:0];
            }
        }
        [self.storage storeConversation:conversation];
    }
    [conversation notifyActivity:activity];
}

@end
