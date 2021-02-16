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

NS_ASSUME_NONNULL_BEGIN

extern  NSString * _Nonnull const CLBCreateUserCompletedNotification;
extern  NSString * _Nonnull const CLBCreateUserFailedNotification;
extern  NSString * _Nonnull const CLBConversationLoadDidStartNotification;
extern  NSString * _Nonnull const CLBConversationLoadDidFinishNotification;

typedef NS_ENUM(NSUInteger, CLBLastLoginResult) {
    CLBLastLoginResultSuccess,
    CLBLastLoginResultFailed,
    CLBLastLoginResultUnknown
};

@interface CLBUserSynchronizer : CLBRemoteOperationScheduler <CLBUserSynchronizerProtocol>

- (instancetype _Nullable)initWithUser:( CLBUser * _Nonnull)user
                synchronizer:(CLBRemoteObjectSynchronizer * _Nonnull)synchronizer
                       appId:(NSString * _Nonnull)appId
          retryConfiguration:(CLBRetryConfiguration * _Nonnull)retryConfiguration
                    settings:(CLBSettings * _Nonnull)settings
                conversation:(CLBConversation * _Nonnull)conversation
  conversationStorageManager:(CLBConversationStorageManager * _Nonnull)conversationStorageManager;

- (void)logInWithCompletionHandler:(void(^_Nullable)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))handler;
- (void)logOutWithCompletionHandler:(void(^_Nullable)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))handler;
- (void)startConversationOrCreateUserWithIntent:(NSString * _Nonnull)intent completionHandler:(void (^_Nullable)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler;
- (void)createConversationOrUserWithName:(nullable NSString *)name description:(nullable NSString *)description iconUrl:(nullable NSString *)iconUrl avatarUrl:(nullable NSString *)avatarUrl metadata:(nullable NSDictionary *)metadata messages:(nullable NSArray<CLBMessage *> *)messages intent:(nullable NSString *)intent completionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler;
- (void)updateConversationById:(NSString *)conversationId withName:(nullable NSString *)name description:(nullable NSString *)description iconUrl:(nullable NSString *)iconUrl metadata:(nullable NSDictionary *)metadata completionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler;
- (void)fetchUserWithCompletionHandler:(void(^)(NSError *error, NSDictionary *userInfo))completionHandler;
- (void)consumeAuthCode:(NSString *)authCode completionHandler:(void(^)(NSError *error, NSDictionary *userInfo))completionHandler;
- (void)upgradeUserWithClientId:(NSString *)clientId completionHandler:(void(^)(void))completionHandler;
- (void)loadConversations:(void (^_Nullable)(NSError *, NSArray *)) handler;
- (void)loadConversationListWithCompletionHandler: (void (^_Nullable)(NSError * _Nullable, CLBConversationList * _Nullable)) handler;
- (void)loadConversation:(NSString *)conversationId completionHandler:(void (^_Nullable)(NSError *, NSDictionary *))handler;

@property(readonly) CLBUser *user;
@property CLBConversationMonitor *conversationMonitor;
@property CLBLastLoginResult lastLoginResult;
@property(nonatomic) CLBConversation *conversation;

@end
NS_ASSUME_NONNULL_END
