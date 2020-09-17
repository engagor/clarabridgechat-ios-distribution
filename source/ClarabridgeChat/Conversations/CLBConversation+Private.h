//
//  CLBConversation+Private.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <ClarabridgeChat/CLBConversation.h>
#import "CLBRemoteObject.h"
#import "CLBFailedUpload.h"

@class CLBMessage;
@class CLBUser;
@class CLBConversationActivity;
@class CLBSettings;
@class CLBParticipant;

@protocol CLBConversationPersistence;

extern NSString * const CLBConversationDidMarkAllAsReadNotification;
extern NSString * const CLBConversationDidRequestPreviousMessagesNotification;
extern NSString * const CLBConversationTypingDidStartNotification;
extern NSString * const CLBConversationTypingDidStopNotification;

@interface CLBConversation (Private) <CLBRemoteObject>

+ (instancetype)conversationWithAppId:(NSString *)appId user:(CLBUser *)user settings:(CLBSettings *)settings;
- (instancetype)initWithAppId:(NSString *)appId user:(CLBUser *)user;

- (void)saveToDisk;
- (void)removeFromDisk;

- (void)clearExpiredMessages;

- (void)addMessage:(CLBMessage *)message;
- (void)handleSuccessfulUpload:(CLBMessage *)message;
- (void)handleFailedUpload:(CLBFailedUpload *)failedUpload;
- (void)notifyActivity:(CLBConversationActivity *)activity;

- (NSString *)messagesRemotePath;

@property NSArray *messages;
@property NSArray *participants;
@property NSString *conversationId;
@property(readonly) BOOL pushEnabled;
@property(readonly) BOOL conversationStarted;
@property CLBUser *user;
@property NSUInteger unreadCount;
@property NSDate *appMakerLastRead;
@property NSString *appId;
@property NSString *displayName;

@property (nonatomic, weak) id<CLBConversationPersistence> persistence;

@end
