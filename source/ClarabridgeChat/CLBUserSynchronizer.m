//
//  CLBUserSynchronizer.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBUserSynchronizer.h"
#import "CLBRemoteObjectSynchronizer.h"
#import "CLBUser+Private.h"
#import "CLBRemoteResponse.h"
#import "CLBUtility.h"
#import "ClarabridgeChat+Private.h"
#import "CLBConfig.h"
#import "CLBConversationMonitor.h"
#import "CLBConfigFetchScheduler.h"
#import "CLBConversation+Private.h"
#import "CLBUserLifecycleManager.h"
#import "CLBApiClient.h"
#import "CLBClientInfo.h"
#import "CLBSettings+Private.h"
#import "CLBUtility.h"
#import "CLBAuthorInfo.h"
#import "CLBConversationList.h"
#import "CLBConversationStorageManager.h"
#import "CLBMessage+Private.h"

NSString *const CLBCreateUserCompletedNotification = @"CLBCreateUserCompletedNotification";
NSString *const CLBCreateUserFailedNotification = @"CLBCreateUserFailedNotification";
NSString *const CLBConversationLoadDidStartNotification = @"CLBConversationLoadDidStartNotification";
NSString *const CLBConversationLoadDidFinishNotification = @"CLBConversationLoadDidFinishNotification";
NSString *const kRequestConversation = @"conversation";
NSString *const kRequestClient = @"client";
NSString *const kRequestIntent = @"intent";
NSString *const kRequestDisplayName = @"displayName";
NSString *const kRequestDescription = @"description";
NSString *const kRequestIconUrl = @"iconUrl";
NSString *const kRequestAvatarUrl = @"avatarUrl";
NSString *const kRequestMetadata = @"metadata";
NSString *const kRequestType = @"type";
NSString *const kConversationTypePersonal = @"personal";
NSString *const kRequestMessages = @"messages";

@interface CLBUserSynchronizer ()

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, strong) CLBRetryConfiguration *retryConfiguration;
@property int retryCount;
@property (nonatomic, strong) NSTimer *retryRequestTimer;
@property CLBSettings *settings;
@property void (^creationCompletedBlock)(NSError *error, NSDictionary *userInfo);
@property NSMutableArray *userCreationCallbacks;
@property CLBConversationStorageManager *conversationStorageManager;

@end

@implementation CLBUserSynchronizer

- (void)dealloc {
    if (self.retryRequestTimer) {
        [self.retryRequestTimer invalidate];
        self.retryRequestTimer = nil;
    }
}

- (instancetype)initWithUser:(CLBUser *)user
                synchronizer:(CLBRemoteObjectSynchronizer *)synchronizer
                       appId:(NSString *)appId
          retryConfiguration:(CLBRetryConfiguration *)retryConfiguration
                    settings:(CLBSettings *)settings
                conversation:(CLBConversation *)conversation
  conversationStorageManager:(CLBConversationStorageManager *)conversationStorageManager {
    self = [super initWithRemoteObject:user synchronizer:synchronizer];
    if (self) {
        self.type = CLBRemoteOperationSchedulerTypeSynchronize;
        self.retryConfiguration = retryConfiguration;
        self.appId = appId;
        self.retryCount = 0;
        self.settings = settings;
        self.userCreationCallbacks = [NSMutableArray array];
        self.lastLoginResult = CLBLastLoginResultUnknown;
        self.conversationStorageManager = conversationStorageManager;
        _conversation = conversation;
    }
    return self;
}

- (CLBUser*)user {
    return (CLBUser*)self.remoteObject;
}

- (void)operationCompleted:(CLBRemoteResponse *)response {
    if (response.error) {
        if ([self shouldClearUserMetadata:response]) {
            NSLog(@"<CLARABRIDGECHAT::WARNING> Invalid user metadata. Removing them");
            // Something is wrong with the local user props. Remove them
            [self.user clearLocalMetadata];
        }
    } else {
        [self.user consolidateMetadata];
    }
}

- (void)operationDidSucceedWithResponse:(NSDictionary *)responseObject {
    [self.user removeRedundancyFromLocalObject];

    NSString *sessionToken = responseObject[@"sessionToken"];

    if (sessionToken) {
        [self updateAuthenticationWithSessionToken:sessionToken];
    }

    if (responseObject[@"conversation"]) {
        [self.conversation deserialize:responseObject];
    }

    if (responseObject[@"conversations"]) {
        [self handleConversationsResponse:responseObject];
    }

    if (!self.conversationMonitor.isConnected && !self.conversationMonitor.isConnecting) {
        [self setRealtimeClient];
    }

    [self connectConversationMonitor];

    [self rescheduleIfNeeded];
}

- (void)handleConversationsResponse:(NSDictionary *)responseObject {
    CLBConversationList *conversationList = [[CLBConversationList alloc] initWithAppId:self.appId user:self.user];
    [conversationList deserialize:responseObject];
    [self.conversationStorageManager storeConversationList:conversationList activeConversationId:self.conversation.conversationId];

    CLBConversation *latestConversation = conversationList.conversations.firstObject;
    if (!latestConversation) {
        return;
    }

    BOOL isActiveConversationUpToDate = NO;
    BOOL isActiveConversationLoaded = self.conversation.conversationId != nil;
    if (isActiveConversationLoaded) {
        isActiveConversationUpToDate = [self.conversationStorageManager messagesAreInSyncInStorageForConversationId:self.conversation.conversationId];
    } else {
        [self.conversation deserialize:responseObject[@"conversations"][0]];
    }

    if (!isActiveConversationUpToDate) {
        [self loadConversation:latestConversation.conversationId completionHandler:^(NSError *error, NSDictionary *response) {
            [self operationDidSucceedWithResponse:response];
        }];
    }
}

- (void)rescheduleIfNeeded {
    if (self.user.settings.profileEnabled && self.user.settings.uploadInterval > 0) {
        self.rescheduleAutomatically = YES;
        self.rescheduleInterval = self.user.settings.uploadInterval;
        [self scheduleImmediately];
    }
}

- (void)connectConversationMonitor {
    if (self.conversation.conversationId != nil && !self.conversationMonitor.isConnected && !self.conversationMonitor.isConnecting) {
        [self.conversationMonitor connect];
    }
}

- (void)setRealtimeClient {
    NSString* fayeEndpoint = CLBGetRealtimeEndpointWithRealtimeSettings(self.user.settings.realtime);
    CLBMZFayeClient* fayeClient = [[CLBMZFayeClient alloc] initWithURL:[NSURL URLWithString:fayeEndpoint]];
    fayeClient.retryInterval = self.user.settings.realtime.retryInterval;
    fayeClient.maximumRetryAttempts = self.user.settings.realtime.maxConnectionAttempts;

    self.conversationMonitor.fayeClient = fayeClient;
}

- (BOOL)shouldIgnoreRequest {
    return !self.user.userId || !self.user.isModified;
}

- (BOOL)shouldClearUserMetadata:(CLBRemoteResponse *)response {
    return response.statusCode >= 400 && response.statusCode < 500 && response.statusCode != 429;
}

- (void)updateAuthenticationWithSessionToken:(NSString *)sessionToken {
    [CLBUserLifecycleManager setLastKnownSessionToken:sessionToken forAppId:self.appId];
    self.settings.sessionToken = sessionToken;
    self.settings.userId = self.user.userId;
}

- (void)logInWithCompletionHandler:(void (^)(NSError *, NSDictionary *))handler {
    if (!self.settings.externalId) {
        return;
    }

    NSString* url = [NSString stringWithFormat:@"/v2/apps/%@/login", self.appId];

    NSMutableDictionary *serializedData = [[NSMutableDictionary alloc] init];

    NSString *sessionToken = self.settings.sessionToken;
    NSString *userId = self.settings.userId;

    if (sessionToken && userId) {
        serializedData[@"sessionToken"] = sessionToken;
        serializedData[@"appUserId"] = userId;
    }

    serializedData[@"userId"] = self.settings.externalId;
    serializedData[@"client"] = [CLBClientInfo serializedClientInfo];

    [self.synchronizer.apiClient requestWithMethod:@"POST" url:url parameters:serializedData completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        if (!error) {
            CLBDebug(@"POST succeeded at : %@\nResponse: %@", url, responseObject);
            self.retryCount = 0;
            self.settings.sessionToken = nil;
            self.settings.userId = nil;
            self.lastLoginResult = CLBLastLoginResultSuccess;
            
            if (responseObject) {
                [self.user deserialize:responseObject];
            } else {
                // Credentials are valid but user doesn't exist yet, set externalId to value from settings
                self.user.externalId = self.settings.externalId;
            }
            
            [self operationDidSucceedWithResponse:responseObject];

            [CLBUserLifecycleManager setLastKnownJwt:self.settings.jwt forAppId:self.appId];
            [CLBUserLifecycleManager setLastKnownExternalId:self.settings.externalId forAppId:self.appId];
            [CLBUserLifecycleManager clearUserIdForAppId:self.appId];
            [CLBUserLifecycleManager clearSessionTokenForAppId:self.appId];

            if (handler) {
                NSDictionary *userInfo = @{
                                           CLBUserIdentifier: self.user
                                           };
                handler(error, userInfo);
            }
        } else {
            CLBDebug(@"POST failed at %@ with : %@, %@", url, serializedData, error);
            [self logIfInvalidAuthError:responseObject];
            self.lastLoginResult = CLBLastLoginResultFailed;
            if ([self shouldRetryError:((NSHTTPURLResponse *)task.response).statusCode]) {
                NSDictionary *userInfo = handler ? @{@"completionHandler": handler} : nil;
                [self retryWithSelector:@selector(handleLoginTimer:) userInfo:userInfo];
            } else if (handler) {
                handler(error, [self errorUserInfoForTask:task response:responseObject]);
            }
        }
    }];
}

- (void)handleLoginTimer:(NSTimer *)timer {
    [self logInWithCompletionHandler:timer.userInfo[@"completionHandler"]];
}

- (void)logOutWithCompletionHandler:(void (^)(NSError *, NSDictionary *))handler {
    NSString *url = [NSString stringWithFormat:@"/v2/apps/%@/appusers/%@/logout", self.appId, self.user.userId];

    NSDictionary *serializedData = @{
                                     @"client": @{
                                             @"id": CLBGetUniqueDeviceIdentifier()
                                             }
                                     };

    [self.synchronizer.apiClient requestWithMethod:@"POST" url:url parameters:serializedData completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        if (error) {
            CLBDebug(@"POST failed at %@ with : %@, %@", url, serializedData, error);
        }else{
            CLBDebug(@"POST succeeded at : %@\nResponse: %@", url, responseObject);
            self.lastLoginResult = CLBLastLoginResultUnknown;
        }

        if (handler) {
            handler(error, [self errorUserInfoForTask:task response:responseObject]);
        }
    }];
}

- (void)startConversationOrCreateUserWithIntent:(NSString *)intent completionHandler:(void (^)(NSError *error, NSDictionary *userInfo))completionHandler {
    BOOL conversationStarted = self.conversation.conversationId != nil;
    if (conversationStarted) {
        if (completionHandler) {
            completionHandler(nil, @{ CLBConversationIdentifier: self.conversation });
        }
        return;
    }
    
    [self createConversationOrUserWithName:nil description:nil iconUrl:nil avatarUrl:nil metadata:nil messages:nil intent:intent completionHandler:completionHandler];
}

- (void)createConversationOrUserWithName:(nullable NSString *)name description:(nullable NSString *)description iconUrl:(nullable NSString *)iconUrl avatarUrl:(nullable NSString *)avatarUrl metadata:(nullable NSDictionary *)metadata messages:(nullable NSArray<CLBMessage *> *)messages intent:(nullable NSString *)intent completionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler {

    @synchronized (self.userCreationCallbacks) {
        if (completionHandler) {
            [self.userCreationCallbacks addObject:completionHandler];
        }
        
        // Prevent two `sendMessage` or `startConversation` calls in quick succession from creating two users.
        // If we notice that a create call is already ongoing, add the completionHandler as a callback of that
        // ongoing operation instead of starting a new one.
        if (!self.creationCompletedBlock) {
            __weak typeof(self) weakSelf = self;
            
            self.creationCompletedBlock = ^(NSError *error, NSDictionary *userInfo) {
                __strong typeof(self) strongSelf = weakSelf;
                
                @synchronized (strongSelf.userCreationCallbacks) {
                    for (void (^completionHandler)(NSError *error, NSDictionary *userInfo) in strongSelf.userCreationCallbacks) {
                        completionHandler(error, userInfo);
                    }
                    [strongSelf.userCreationCallbacks removeAllObjects];
                    strongSelf.creationCompletedBlock = nil;
                }
            };

            NSMutableDictionary *parameters = @{kRequestType: kConversationTypePersonal }.mutableCopy;

            if(name) {
                parameters[kRequestDisplayName] = name;
            }

            if(description) {
                parameters[kRequestDescription] = description;
            }

            if(iconUrl) {
                parameters[kRequestIconUrl] = iconUrl;
            }
            
            if(metadata) {
                parameters[kRequestMetadata] = metadata;
            }
            
            if(messages) {
                NSMutableArray *messageArray = NSMutableArray.new;

                for (CLBMessage *message in messages) {
                    [messageArray addObject:[message serializeTextForConversation]];
                }

                parameters[kRequestMessages] = messageArray;
            }

            BOOL userExists = self.user.userId != nil;
            if (userExists) {
                [self createConversationWithParameters:parameters intent:intent completionHandler:self.creationCompletedBlock];
            } else {
                [self createUserWithParameters:parameters avatarUrl:avatarUrl intent:intent completionHandler:self.creationCompletedBlock];
            }
        }
    }
}

- (void)createConversationWithParameters:(NSDictionary *)parameters intent:(NSString *)intent completionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler {

    NSString *url = [NSString stringWithFormat:@"/v2/apps/%@/appusers/%@/conversations", self.appId, self.user.userId];
    NSMutableDictionary *mutableParameters = @{
        kRequestClient:[CLBClientInfo serializedClientInfo],
        kRequestIntent: intent,
    }.mutableCopy;

    [mutableParameters addEntriesFromDictionary:parameters];

    [self.synchronizer.apiClient requestWithMethod:@"POST" url:url parameters:mutableParameters completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        NSDictionary* userInfo;
        if (error) {
            CLBDebug(@"POST failed at : %@, %@", url, error);
            userInfo = [self errorUserInfoForTask:task response:responseObject];
        }else{
            CLBDebug(@"POST succeeded at : %@\nResponse: %@", url, responseObject);
            self.user.conversationStarted = YES;
            [self operationDidSucceedWithResponse:responseObject];

            userInfo = @{
                         CLBConversationIdentifier: self.conversation
                         };
        }

        if (completionHandler) {
            completionHandler(error, userInfo);
        }
    }];
}

- (void)createUserWithParameters:(nullable NSDictionary *)parameters avatarUrl:(nullable NSString *)avatarUrl intent:(NSString *)intent completionHandler:(void (^)(NSError *, NSDictionary *))handler {
    NSString *url = [NSString stringWithFormat:@"/v2/apps/%@/appusers", self.appId];
    NSMutableDictionary* serializedData = [[self.user serialize] mutableCopy];
    [serializedData setObject:intent forKey:@"intent"];

    
    if (avatarUrl && avatarUrl.length > 0) {
        [serializedData setObject:avatarUrl forKey:kRequestAvatarUrl];
    }
    
    if (parameters != NULL) {
        NSDictionary *conversationParameters = @{kRequestConversation:parameters};
        [serializedData addEntriesFromDictionary:conversationParameters];
    }

    [self.synchronizer.apiClient requestWithMethod:@"POST" url:url parameters:serializedData completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        NSDictionary* userInfo;
        if (error) {
            CLBDebug(@"POST failed at %@ with : %@, %@", url, serializedData, error);
            
            userInfo = [self errorUserInfoForTask:task response:responseObject];
        }else{
            CLBDebug(@"POST succeeded at : %@\nResponse: %@", url, responseObject);
            [self.user deserialize:responseObject];
            [self operationDidSucceedWithResponse:responseObject];
            
            [CLBUserLifecycleManager setLastKnownUserId:self.user.userId forAppId:self.appId];
            
            userInfo = @{
                         CLBConversationIdentifier: self.conversation
                         };
        }
        if (handler) {
            handler(error, userInfo);
        }
    }];
}

- (void)updateConversationById:(NSString *)conversationId withName:(nullable NSString *)name description:(nullable NSString *)description iconUrl:(nullable NSString *)iconUrl metadata:(nullable NSDictionary *)metadata completionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler {

    NSString *url = [NSString stringWithFormat:@"/v2/apps/%@/conversations/%@", self.appId, conversationId];

    NSMutableDictionary *parameters = @{kRequestClient:[CLBClientInfo serializedClientInfo]}.mutableCopy;

    if(name) {
        parameters[kRequestDisplayName] = name;
    }

    if(description) {
        parameters[kRequestDescription] = description;
    }

    if(iconUrl) {
        parameters[kRequestIconUrl] = iconUrl;
    }

    if(metadata) {
        parameters[kRequestMetadata] = metadata;
    }

    [self.synchronizer.apiClient requestWithMethod:@"PUT" url:url parameters:parameters completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        NSDictionary* userInfo;
        if (error) {
            CLBDebug(@"POST failed at : %@, %@", url, error);
            userInfo = [self errorUserInfoForTask:task response:responseObject];
        }else{
            CLBDebug(@"POST succeeded at : %@\nResponse: %@", url, responseObject);
            userInfo = @{CLBConversationIdentifier: self.conversation};
        }

        if (completionHandler) {
            completionHandler(error, userInfo);
        }
    }];

}

- (void)loadConversations: (void (^)(NSError *, NSArray * _Nonnull)) handler {
    CLBConversationList *conversationList = [self.conversationStorageManager getConversationList];
    handler(nil, conversationList.conversations);
}

- (void)loadConversationListWithCompletionHandler: (void (^)(NSError *, CLBConversationList * _Nullable)) handler {
   CLBConversationList *conversationList = [self.conversationStorageManager getConversationList];
   handler(nil, conversationList);
}

- (void)loadConversation:(NSString *)conversationId completionHandler:(void (^)(NSError *, NSDictionary *))handler {
    void (^loadConversationHandler)(NSError *, NSDictionary *) = ^(NSError *error, NSDictionary *userInfo){
        if (!self.user.userId) {
            [self handleNoUserIdInRequest:handler];
            return;
        }

        NSString* endpoint = [NSString stringWithFormat:@"/v2/apps/%@/conversations/%@/subscribe", self.appId, conversationId];
        
        NSDictionary* parameters = @{
                                     @"author": [CLBAuthorInfo authorFieldForUser:self.user]
                                     };
        
        [self.synchronizer.apiClient requestWithMethod:@"POST" url:endpoint parameters:parameters completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
            NSDictionary* userInfo;
            if (error) {
                userInfo = [self errorUserInfoForTask:task response:responseObject];
            } else {
                [self operationDidSucceedWithResponse:responseObject];
            }
            
            if (handler) {
                handler(error, userInfo);
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationLoadDidFinishNotification object:nil];
        }];
    };
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationLoadDidStartNotification object:nil];
    
    // Force a last user sync if they still don't have an userId but logged in with valid creds
    BOOL shouldRefreshAuthenticatedUser = self.user.externalId && !self.user.userId;
    
    if (shouldRefreshAuthenticatedUser) {
        [self logInWithCompletionHandler:loadConversationHandler];
    } else {
        loadConversationHandler(nil, nil);
    }
}

- (void)handleNoUserIdInRequest: (void (^)(NSError *, NSDictionary *)) handler {
    NSError* error = [NSError errorWithDomain:CLBErrorDomainIdentifier code:400 userInfo:nil];

    NSDictionary *userInfo = @{
                               CLBErrorCodeIdentifier: @"bad_request",
                               CLBStatusCodeIdentifier: @400,
                               CLBErrorDescriptionIdentifier: @"Load conversation called for user with nil appUserId. Ignoring!"
                               };

    if (handler) {
        handler(error, userInfo);
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationLoadDidFinishNotification object:nil];
    return;
}

- (void)retryWithSelector:(SEL)selector userInfo:(NSDictionary *)userInfo {
    self.retryCount++;
    CLBEnsureMainThread(^{
        self.retryRequestTimer = [NSTimer scheduledTimerWithTimeInterval:self.retryConfiguration.baseRetryIntervalAggressive target:self selector:selector userInfo:userInfo repeats:NO];
    });
}

- (void)handleUserFetchTimer:(NSTimer *)timer {
    [self fetchUserWithCompletionHandler:timer.userInfo[@"completionHandler"]];
}

- (void)fetchUserWithCompletionHandler:(void (^)(NSError *, NSDictionary *))handler {
    [self.synchronizer fetch:self.user completion:^(CLBRemoteResponse *response) {
        if (!response.error) {
            self.retryCount = 0;
            [self operationDidSucceedWithResponse:response.responseObject];

            if (handler) {
                NSDictionary *userInfo = @{ CLBUserIdentifier: self.user };
                handler(response.error, userInfo);
            }
        } else {
            if ([self shouldRetryError:response.statusCode]) {
                NSDictionary *userInfo = handler ? @{@"completionHandler": handler} : nil;
                [self retryWithSelector:@selector(handleUserFetchTimer:) userInfo:userInfo];
            } else if (handler) {
                handler(response.error, [self errorUserInfoForStatusCode:response.statusCode response:response.responseObject]);
            }
        }
    }];
}

- (void)handleConsumeAuthCodeTimer:(NSTimer *)timer {
    [self consumeAuthCode:timer.userInfo[@"authCode"] completionHandler:timer.userInfo[@"completionHandler"]];
}

- (void)consumeAuthCode:(NSString *)authCode completionHandler:(void (^)(NSError *error, NSDictionary *userInfo))completionHandler {
    NSString *url = [NSString stringWithFormat:@"/v2/apps/%@/appusers/authcode", self.appId];
    NSDictionary* serializedData = @{ @"authCode": authCode, @"client": [CLBClientInfo serializedClientInfo]};

    [self.synchronizer.apiClient requestWithMethod:@"POST" url:url parameters:serializedData completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        if (error) {
            CLBDebug(@"POST failed at %@ with : %@, %@", url, serializedData, error);
            if ([self shouldRetryError:((NSHTTPURLResponse *)task.response).statusCode]) {
                NSDictionary *userInfo = @{@"completionHandler": completionHandler, @"authCode": authCode};
                [self retryWithSelector:@selector(handleConsumeAuthCodeTimer:) userInfo:userInfo];
                return;
            }

            if (completionHandler) {
                completionHandler(error, [self errorUserInfoForTask:task response:responseObject]);
            }
        } else {
            self.retryCount = 0;
            CLBDebug(@"POST succeeded at : %@\nResponse: %@", url, responseObject);

            self.user.userId = responseObject[@"appUser"][@"_id"];
            self.user.externalId = nil;
            self.settings.userId = self.user.userId;
            self.settings.externalId = nil;
            self.settings.jwt = nil;

            [CLBUserLifecycleManager clearExternalIdForAppId:self.appId];
            [CLBUserLifecycleManager clearJwtForAppId:self.appId];
            [CLBUserLifecycleManager setLastKnownUserId:self.user.userId forAppId:self.appId];
            [self updateAuthenticationWithSessionToken:responseObject[@"appUser"][@"sessionToken"]];

            if (completionHandler) {
                completionHandler(error, nil);
            }
        }
    }];
}

- (void)handleUpgradeUserTimer:(NSTimer *)timer {
    [self upgradeUserWithClientId:timer.userInfo[@"clientId"] completionHandler:timer.userInfo[@"completionHandler"]];
}

- (void)upgradeUserWithClientId:(NSString *)clientId completionHandler:(void (^)(void))completionHandler {
    NSString *url = [NSString stringWithFormat:@"/v2/apps/%@/appusers/upgrade", self.appId];
    NSDictionary* serializedData = @{ @"clientId": clientId };

    [self.synchronizer.apiClient requestWithMethod:@"POST" url:url parameters:serializedData completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        if (error) {
            CLBDebug(@"POST failed at %@ with : %@, %@", url, serializedData, error);
            if ([self shouldRetryError:((NSHTTPURLResponse *)task.response).statusCode]) {
                NSDictionary *userInfo = @{@"completionHandler": completionHandler, @"clientId": clientId};
                [self retryWithSelector:@selector(handleUpgradeUserTimer:) userInfo:userInfo];
                return;
            }
        } else {
            self.retryCount = 0;
            CLBDebug(@"POST succeeded at : %@\nResponse: %@", url, responseObject);
            self.user.userId = responseObject[@"appUser"][@"_id"];

            [CLBUserLifecycleManager setLastKnownUserId:self.user.userId forAppId:self.appId];
            [self updateAuthenticationWithSessionToken:responseObject[@"appUser"][@"sessionToken"]];
        }

        if (completionHandler) {
            completionHandler();
        }
    }];
}

- (BOOL)shouldRetryError:(NSInteger)statusCode {
    BOOL isRetryableStatusCode = statusCode == 429 || statusCode >= 500;
    return isRetryableStatusCode && self.retryCount < self.retryConfiguration.maxRetries;
}

- (void)logIfInvalidAuthError:(id)response {
    BOOL isInvalidAuth = [response isKindOfClass:[NSDictionary class]] && [response[@"error"][@"code"] isEqualToString:@"invalid_auth"];

    if (isInvalidAuth) {
        NSLog(@"<CLARABRIDGECHAT::ERROR> Provided credentials were invalid. Either your app id, JWT, or both are incorrect.");
    }
}

- (NSDictionary *)errorUserInfoForTask:(NSURLSessionDataTask *)task response:(id)response {
    NSInteger statusCode = [task.response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)task.response).statusCode : 0;

    return [self errorUserInfoForStatusCode:statusCode response:response];
}

- (NSDictionary *)errorUserInfoForStatusCode:(NSInteger)statusCode response:(id)response {
    NSString *errorCode = [response isKindOfClass:[NSDictionary class]] ? response[@"error"][@"code"] : @"";
    NSString *errorDescription = [response isKindOfClass:[NSDictionary class]] ? response[@"error"][@"description"] : @"";

    return @{
             CLBErrorCodeIdentifier: errorCode ?: @"",
             CLBErrorDescriptionIdentifier: errorDescription ?: @"",
             CLBStatusCodeIdentifier: [NSNumber numberWithInteger:statusCode]
             };
}

@end
