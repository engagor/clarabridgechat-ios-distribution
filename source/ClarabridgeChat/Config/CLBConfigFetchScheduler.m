//
//  CLBConfigFetchScheduler.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBConfigFetchScheduler.h"
#import "CLBConfig.h"
#import "CLBUtility.h"
#import "CLBRemoteResponse.h"
#import "CLBRemoteObjectSynchronizer.h"
#import "CLBApiClient.h"
#import "ClarabridgeChat+Private.h"
#import "CLBSettings+Private.h"


static NSString *const CLBErrorUnxpectedInitializationRetrying = @"<CLARABRIDGECHAT::ERROR> An unexpected error occurred during initialization. Retrying in %ld seconds... \nError: %@ \nResponse: %@ \n";
static NSString *const CLBErrorInitializationRetryExhausted = @"<CLARABRIDGECHAT::ERROR> An unexpected error occurred during initialization. Retry attempts are exhausted. \nError: %@ \nResponse: %@ \n";
static NSString *const CLBErrorCredentialsNotSupplied = @"<CLARABRIDGECHAT::ERROR> Required credentials not supplied. Either your integration id was empty, or this user requires a JWT and none was provided.";
static NSString *const CLBErrorProvidedCredentialsInvalid = @"<CLARABRIDGECHAT::ERROR> Provided credentials were invalid. Either your integration id, JWT, or both are incorrect.";
static NSString *const CLBErrorCouldNotReachServer = @"<CLARABRIDGECHAT::ERROR> Could not reach server. Provided integration id is invalid.";

@interface CLBConfigFetchScheduler()
@property int retryCount;
@end

@implementation CLBConfigFetchScheduler

- (instancetype)initWithConfig:(CLBConfig *)config synchronizer:(CLBRemoteObjectSynchronizer *)synchronizer {
    self = [super initWithRemoteObject:config synchronizer:synchronizer];
    return self;
}

- (CLBConfig *)config {
    return self.remoteObject;
}

- (BOOL)shouldIgnoreRequest {
    return self.config.validityStatus != CLBAppStatusUnknown;
}

- (void)scheduleImmediatelyWithCompletion:(void (^)(NSError *, NSDictionary *))callback {
    self.fetchCompletionHandler = callback;
    @synchronized(self) {
        self.isInitializationComplete = NO;
    }
    
    // Analogous to process.nextTick
    // Allows you to call `login` directly after `init`
    [self scheduleAfter:0];
}

- (void)operationCompleted:(CLBRemoteResponse *)response {
    response.error ? [self operationDidFail:response] : [self operationDidSucceed:response];
}

- (void)addCallbackOnInitializationComplete:(void (^)(void))callback {
    if (!self.callbacksOnInitComplete) {
        self.callbacksOnInitComplete = [[NSMutableArray alloc] init];
    }
    [self.callbacksOnInitComplete addObject:callback];
}

- (void)operationDidFail:(CLBRemoteResponse *)response {
    if (response.error.code == kCFURLErrorCannotFindHost || response.statusCode == 404) {
        [self handleAppNotFound:response.error statusCode:404];
    } else if([response.clbErrorCode isEqualToString:@"invalid_auth"]) {
        [self handleInvalidAuth:response];
    } else if([response.clbErrorCode isEqualToString:@"unauthorized"]) {
        [self handleUnauthorized:response];
    } else {
        [self handleUnknownStatus:response];
    }
}

- (void)handleUnknownStatus:(CLBRemoteResponse *)response {
    self.config.validityStatus = CLBAppStatusUnknown;

    if (self.retryCount < self.config.retryConfiguration.maxRetries) {
        BOOL isTimeoutError = response.error.code == kCFURLErrorTimedOut && [response.error.domain isEqualToString:NSURLErrorDomain];
        BOOL retryAggressively = [ClarabridgeChat isConversationShown] && !isTimeoutError;

        int baseRetryInterval = [self baseRetryInterval:retryAggressively];

        NSInteger jitteredWaitInterval = [self.config.retryConfiguration jitteredWaitIntervalWithBaseInterval:baseRetryInterval retryCount:self.retryCount];

        NSLog(CLBErrorUnxpectedInitializationRetrying, (long)jitteredWaitInterval, [response.error localizedDescription], response.httpResponse);
        [self scheduleAfter:jitteredWaitInterval];

        self.retryCount++;
    } else {
        NSLog(CLBErrorInitializationRetryExhausted, [response.error localizedDescription], response.httpResponse);

        [self notifyInitializationFailedWithError:response.error
                                             code:response.clbErrorCode
                                       statusCode:response.statusCode
                                      description:response.responseObject[@"error"][@"description"]];
    }
}

- (int)baseRetryInterval:(BOOL)retryAggressively {
    int aggressive = (int) self.config.retryConfiguration.baseRetryIntervalAggressive;
    int regular = (int) self.config.retryConfiguration.baseRetryIntervalRegular;
    return retryAggressively ? aggressive : regular;
}

- (void)handleUnauthorized:(CLBRemoteResponse *)response {
    NSLog(CLBErrorCredentialsNotSupplied);
    self.config.validityStatus = CLBAppStatusInvalid;
    [self notifyInitializationFailedWithError:response.error
                                         code:response.clbErrorCode
                                   statusCode:response.statusCode
                                  description:response.responseObject[@"error"][@"description"]];
}

- (void)handleInvalidAuth:(CLBRemoteResponse *)response {
    NSLog(CLBErrorProvidedCredentialsInvalid);
    self.config.validityStatus = CLBAppStatusInvalid;
    [self notifyInitializationFailedWithError:response.error
                                         code:response.clbErrorCode
                                   statusCode:response.statusCode
                                  description:response.responseObject[@"error"][@"description"]];
}

- (void)handleAppNotFound:(NSError *)error statusCode:(NSInteger) statusCode {
    NSLog(CLBErrorCouldNotReachServer);
    self.config.validityStatus = CLBAppStatusInvalid;
    [self notifyInitializationFailedWithError:error code:@"app_not_found"
                                   statusCode:statusCode
                                  description:@"App not found"];
}

- (void)notifyInitializationFailedWithError:(NSError *)error
                                       code:(NSString *)errorCode
                                 statusCode:(NSInteger) statusCode
                                description:(NSString *)errorDescription {
    NSDictionary *userInfo = @{
                               CLBErrorCodeIdentifier: errorCode ?: @"",
                               CLBStatusCodeIdentifier: [NSNumber numberWithInteger:statusCode],
                               CLBErrorDescriptionIdentifier: errorDescription ?: @""
                               };

    if (self.fetchCompletionHandler) {
        self.fetchCompletionHandler(error, userInfo);
    }
}

- (void)operationDidSucceed:(CLBRemoteResponse *)response {
    if ([self isAppValid]) {
        if (self.delegate != nil) {
            [self.delegate configFetchScheduler:self didUpdateAppId:self.config.appId];
        }
        [self initializationDidComplete];
    } else {
        self.config.validityStatus = CLBAppStatusInvalid;
        [self notifyInitializationFailedWithError:[NSError errorWithDomain:CLBErrorDomainIdentifier code:401 userInfo:nil]
                                             code:@"invalid_app"
                                       statusCode:401
                                      description:@"Invalid app/SDK version"];
    }
}

- (void)initializationDidComplete {
    @synchronized(self) {
        self.isInitializationComplete = YES;
        for(void (^callback)(NSError *error, NSDictionary *userInfo) in self.callbacksOnInitComplete){
            callback(nil, nil);
        }
        [self.callbacksOnInitComplete removeAllObjects];
    }
}

- (BOOL)isAppValid {
    // Determine app/SDK validity
    return ([self.config isAppActive] && [self.config hasValidUrl]);
}

- (void)logPushTokenIfExists {
    NSString *pushToken = CLBGetPushNotificationDeviceToken();
    if(pushToken){
        NSLog(@"<CLARABRIDGECHAT::INFO> Push token successfully uploaded : %@", pushToken);
    }
}

@end
