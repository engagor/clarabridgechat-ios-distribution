//
//  CLBUserSynchronizer.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBRemoteOperationScheduler.h"
@class CLBUser;
@class CLBConversationMonitor;
@class CLBRetryConfiguration;
@class CLBSettings;
@class CLBConversation;
@class CLBConversationStorageManager;

extern NSString *const CLBCreateUserCompletedNotification;
extern NSString *const CLBCreateUserFailedNotification;
extern NSString *const CLBConversationLoadDidStartNotification;
extern NSString *const CLBConversationLoadDidFinishNotification;

typedef NS_ENUM(NSUInteger, CLBLastLoginResult) {
    CLBLastLoginResultSuccess,
    CLBLastLoginResultFailed,
    CLBLastLoginResultUnknown
};

@interface CLBUserSynchronizer : CLBRemoteOperationScheduler

- (instancetype)initWithUser:(CLBUser *)user
                synchronizer:(CLBRemoteObjectSynchronizer*)synchronizer
                       appId:(NSString *)appId
          retryConfiguration:(CLBRetryConfiguration *)retryConfiguration
                    settings:(CLBSettings *)settings
                conversation:(CLBConversation *)conversation
  conversationStorageManager:(CLBConversationStorageManager *)conversationStorageManager;

- (void)logInWithCompletionHandler:(void(^)(NSError *error, NSDictionary *userInfo))handler;
- (void)logOutWithCompletionHandler:(void(^)(NSError *error, NSDictionary *userInfo))handler;
- (void)startConversationOrCreateUserWithIntent:(NSString *)intent completionHandler:(void (^)(NSError *error, NSDictionary *userInfo))completionHandler;
- (void)fetchUserWithCompletionHandler:(void(^)(NSError *error, NSDictionary *userInfo))completionHandler;
- (void)consumeAuthCode:(NSString *)authCode completionHandler:(void(^)(NSError *error, NSDictionary *userInfo))completionHandler;
- (void)upgradeUserWithClientId:(NSString *)clientId completionHandler:(void(^)(void))completionHandler;
- (void)loadConversations:(void (^)(NSError *, NSArray *)) handler;
- (void)loadConversation:(NSString *)conversationId completionHandler:(void (^)(NSError *, NSDictionary *))handler;

@property(readonly) CLBUser *user;
@property CLBConversationMonitor *conversationMonitor;
@property CLBLastLoginResult lastLoginResult;
@property CLBConversation *conversation;

@end
