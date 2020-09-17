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

NSString *const CLBCreateUserCompletedNotification = @"CLBCreateUserCompletedNotification";
NSString *const CLBCreateUserFailedNotification = @"CLBCreateUserFailedNotification";
NSString *const CLBConversationLoadDidStartNotification = @"CLBConversationLoadDidStartNotification";
NSString *const CLBConversationLoadDidFinishNotification = @"CLBConversationLoadDidFinishNotification";

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
        if ([self shouldClearUserProperties:response]) {
            NSLog(@"<CLARABRIDGECHAT::WARNING> Invalid user properties. Removing them");
            // Something is wrong with the local user props. Remove them
            [self.user clearLocalProperties];
        }
    } else {
        [self.user consolidateProperties];
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
    [self.conversationStorageManager storeConversationList:conversationList];

    CLBConversation *latestConversation = conversationList.conversations.firstObject;
    BOOL hasConversationId = self.conversation.conversationId != nil;

    if (!hasConversationId && latestConversation) {
        [self.conversation deserialize:responseObject[@"conversations"][0]];
    }

    BOOL activeConversationIsUpToDate = [self.conversationStorageManager activeConversationIsUpToDate:conversationList];

    if ((!activeConversationIsUpToDate) && latestConversation) {
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
    return !self.user.appUserId || !self.user.isModified;
}

- (BOOL)shouldClearUserProperties:(CLBRemoteResponse *)response {
    return response.statusCode >= 400 && response.statusCode < 500 && response.statusCode != 429;
}

- (void)updateAuthenticationWithSessionToken:(NSString *)sessionToken {
    [CLBUserLifecycleManager setLastKnownSessionToken:sessionToken forAppId:self.appId];
    self.settings.sessionToken = sessionToken;
    self.settings.appUserId = self.user.appUserId;
}

- (void)logInWithCompletionHandler:(void (^)(NSError *, NSDictionary *))handler {
    if (!self.settings.userId) {
        return;
    }

    NSString* url = [NSString stringWithFormat:@"/v2/apps/%@/login", self.appId];

    NSMutableDictionary *serializedData = [[NSMutableDictionary alloc] init];

    NSString *sessionToken = self.settings.sessionToken;
    NSString *appUserId = self.settings.appUserId;

    if (sessionToken && appUserId) {
        serializedData[@"sessionToken"] = sessionToken;
        serializedData[@"appUserId"] = appUserId;
    }

    serializedData[@"userId"] = self.settings.userId;
    serializedData[@"client"] = [CLBClientInfo serializedClientInfo];

    [self.synchronizer.apiClient requestWithMethod:@"POST" url:url parameters:serializedData completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        if (!error) {
            CLBDebug(@"POST succeeded at : %@\nResponse: %@", url, responseObject);
            self.retryCount = 0;
            self.settings.sessionToken = nil;
            self.settings.appUserId = nil;
            self.lastLoginResult = CLBLastLoginResultSuccess;
            
            if (responseObject) {
                [self.user deserialize:responseObject];
            } else {
                // Credentials are valid but user doesn't exist yet, set userId to value from settings
                self.user.userId = self.settings.userId;
            }
            
            [self operationDidSucceedWithResponse:responseObject];

            [CLBUserLifecycleManager setLastKnownJwt:self.settings.jwt forAppId:self.appId];
            [CLBUserLifecycleManager setLastKnownUserId:self.settings.userId forAppId:self.appId];
            [CLBUserLifecycleManager clearAppUserIdForAppId:self.appId];
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
    NSString *url = [NSString stringWithFormat:@"/v2/apps/%@/appusers/%@/logout", self.appId, self.user.appUserId];

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
            
            BOOL userExists = self.user.appUserId != nil;
            if (userExists) {
                [self startConversationWithIntent:intent completionHandler:self.creationCompletedBlock];
            } else {
                [self createUserWithIntent:intent completionHandler:self.creationCompletedBlock];
            }
        }
    }
}

- (void)createUserWithIntent:(NSString *)intent completionHandler:(void (^)(NSError *, NSDictionary *))handler {
    NSString *url = [NSString stringWithFormat:@"/v2/apps/%@/appusers", self.appId];
    NSMutableDictionary* serializedData = [[self.user serialize] mutableCopy];
    [serializedData setObject:intent forKey:@"intent"];

    [self.synchronizer.apiClient requestWithMethod:@"POST" url:url parameters:serializedData completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        NSDictionary* userInfo;
        if (error) {
            CLBDebug(@"POST failed at %@ with : %@, %@", url, serializedData, error);
            
            userInfo = [self errorUserInfoForTask:task response:responseObject];
        }else{
            CLBDebug(@"POST succeeded at : %@\nResponse: %@", url, responseObject);
            [self.user deserialize:responseObject];
            [self operationDidSucceedWithResponse:responseObject];
            
            [CLBUserLifecycleManager setLastKnownAppUserId:self.user.appUserId forAppId:self.appId];
            
            userInfo = @{
                         CLBConversationIdentifier: self.conversation
                         };
        }

        if (handler) {
            handler(error, userInfo);
        }
    }];
}

- (void)startConversationWithIntent:(NSString *)intent completionHandler:(void (^)(NSError *, NSDictionary *))handler {
    NSString *url = [NSString stringWithFormat:@"/v2/apps/%@/appusers/%@/conversation", self.appId, self.user.appUserId];
    NSDictionary *mutableParameters = @{@"client":[CLBClientInfo serializedClientInfo], @"intent": intent};

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

        if (handler) {
            handler(error, userInfo);
        }
    }];
}

- (void)loadConversations: (void (^)(NSError *, NSArray *)) handler {
    CLBConversationList *conversationList = [self.conversationStorageManager getConversationList];
    handler(nil, conversationList.conversations);
}

- (void)loadConversation:(NSString *)conversationId completionHandler:(void (^)(NSError *, NSDictionary *))handler {
    void (^loadConversationHandler)(NSError *, NSDictionary *) = ^(NSError *error, NSDictionary *userInfo){
        if (!self.user.appUserId) {
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
    
    // Force a last user sync if they still don't have an appUserId but logged in with valid creds
    BOOL shouldRefreshAuthenticatedUser = self.user.userId && !self.user.appUserId;
    
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

            self.user.appUserId = responseObject[@"appUser"][@"_id"];
            self.user.userId = nil;
            self.settings.appUserId = self.user.appUserId;
            self.settings.userId = nil;
            self.settings.jwt = nil;

            [CLBUserLifecycleManager clearUserIdForAppId:self.appId];
            [CLBUserLifecycleManager clearJwtForAppId:self.appId];
            [CLBUserLifecycleManager setLastKnownAppUserId:self.user.appUserId forAppId:self.appId];
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
            self.user.appUserId = responseObject[@"appUser"][@"_id"];

            [CLBUserLifecycleManager setLastKnownAppUserId:self.user.appUserId forAppId:self.appId];
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
