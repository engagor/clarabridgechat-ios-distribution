//
//  CLBUserSynchronizer.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBRemoteOperationScheduler.h"
#import "CLBUserSynchronizerProtocol.h"

@class CLBUser;
@class CLBConversationMonitor;
@class CLBRetryConfiguration;
@class CLBSettings;
@class CLBConversation;
@class CLBConversationStorageManager;
@class CLBConversationList;

extern NSString *const CLBCreateUserCompletedNotification;
extern NSString *const CLBCreateUserFailedNotification;
extern NSString *const CLBConversationLoadDidStartNotification;
extern NSString *const CLBConversationLoadDidFinishNotification;

typedef NS_ENUM(NSUInteger, CLBLastLoginResult) {
    CLBLastLoginResultSuccess,
    CLBLastLoginResultFailed,
    CLBLastLoginResultUnknown
};

@interface CLBUserSynchronizer : CLBRemoteOperationScheduler <CLBUserSynchronizerProtocol>

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
- (void)createConversationOrUserWithName:(nullable NSString *)name description:(nullable NSString *)description iconUrl:(nullable NSString *)iconUrl avatarUrl:(nullable NSString *)avatarUrl metadata:(nullable NSDictionary *)metadata messages:(nullable NSArray<CLBMessage *> *)messages intent:(nullable NSString *)intent completionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler;
- (void)updateConversationById:(NSString *)conversationId withName:(nullable NSString *)name description:(nullable NSString *)description iconUrl:(nullable NSString *)iconUrl metadata:(nullable NSDictionary *)metadata completionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler;
- (void)fetchUserWithCompletionHandler:(void(^)(NSError *error, NSDictionary *userInfo))completionHandler;
- (void)consumeAuthCode:(NSString *)authCode completionHandler:(void(^)(NSError *error, NSDictionary *userInfo))completionHandler;
- (void)upgradeUserWithClientId:(NSString *)clientId completionHandler:(void(^)(void))completionHandler;
- (void)loadConversations:(void (^)(NSError *, NSArray *)) handler;
- (void)loadConversationListWithCompletionHandler: (void (^_Nullable)(NSError * _Nullable, CLBConversationList * _Nullable)) handler;
- (void)loadConversation:(NSString *)conversationId completionHandler:(void (^)(NSError *, NSDictionary *))handler;

@property(readonly) CLBUser *user;
@property CLBConversationMonitor *conversationMonitor;
@property CLBLastLoginResult lastLoginResult;
@property(nonatomic) CLBConversation *conversation;

@end
