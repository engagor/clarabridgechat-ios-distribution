//
//  CLBRemoteSettingsFetchScheduler.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBRemoteSettingsFetchScheduler.h"
#import "CLBRemoteSettings.h"
#import "CLBUser+Private.h"
#import "CLBUtility.h"
#import "CLBRulesEngine.h"
#import "CLBRemoteResponse.h"
#import "ClarabridgeChat+Private.h"
#import "CLBRemoteObjectSynchronizer.h"
#import "CLBApiClient.h"
#import "CLBUserSynchronizer.h"
#import "CLBDependencyManager.h"

static const int kBaseRetryIntervalAggressiveStrategy = 15;
static const int kBaseRetryIntervalRegularStrategy = 60;
static const int kMaxNumberOfRetries = 5;
static const int kRetryBackoffMultiplier = 2;

@interface CLBRemoteSettingsFetchScheduler()

@property int retryCount;
@property CLBUserSynchronizer* userSynchronizer;

@end

@implementation CLBRemoteSettingsFetchScheduler

-(instancetype)initWithRemoteSettings:(CLBRemoteSettings *)settings userSynchronizer:(CLBUserSynchronizer*)userSynchronizer
{
    self = [super initWithRemoteObject:settings synchronizer:userSynchronizer.synchronizer];
    if(self){
        _validityStatus = CLBAppTokenStatusUnknown;
        _userSynchronizer = userSynchronizer;
    }
    return self;
}

-(CLBRemoteSettings*)remoteSettings
{
    return self.remoteObject;
}

-(BOOL)shouldIgnoreRequest
{
    return self.validityStatus != CLBAppTokenStatusUnknown;
}

-(void)scheduleImmediately
{
    // Analogous to process.nextTick
    // Allows you to call `login` directly after `init`
    [self scheduleAfter:0];
}

-(void)operationCompleted:(CLBRemoteResponse *)response
{
    if(response.error){
        if([response.clbErrorCode isEqualToString:@"invalid_auth"]){
            NSLog(@"<CLARABRIDGECHAT::ERROR> Provided credentials were invalid. Either your app token, JWT, or both are incorrect.");
            self.validityStatus = CLBAppTokenStatusInvalid;
            [self notifyInitializationFailedWithErrorCode:response.clbErrorCode statusCode:response.statusCode];
        }else if([response.clbErrorCode isEqualToString:@"unauthorized"]){
            NSLog(@"<CLARABRIDGECHAT::ERROR> Required credentials not supplied. Either your app token was empty, or this user requires a JWT and none was provided.");
            self.validityStatus = CLBAppTokenStatusInvalid;
            [self notifyInitializationFailedWithErrorCode:response.clbErrorCode statusCode:response.statusCode];
        }else{
            self.validityStatus = CLBAppTokenStatusUnknown;

            if (self.retryCount < kMaxNumberOfRetries) {
                BOOL isTimeoutError = response.error.code == kCFURLErrorTimedOut && [response.error.domain isEqualToString:NSURLErrorDomain];
                BOOL retryAggressively = [ClarabridgeChat isConversationShown] && !isTimeoutError;

                int baseRetryInterval = retryAggressively ? kBaseRetryIntervalAggressiveStrategy : kBaseRetryIntervalRegularStrategy;
                int waitInterval = baseRetryInterval * pow(kRetryBackoffMultiplier, self.retryCount);

                int jitteredWaitInterval = ((2 * waitInterval) / 3) + arc4random_uniform(waitInterval / 3);

                NSLog(@"<CLARABRIDGECHAT::ERROR> An unexpected error occurred during initialization. Retrying in %d seconds... \nError: %@ \nResponse: %@ \n", jitteredWaitInterval, [response.error localizedDescription], response.httpResponse);
                [self scheduleAfter:jitteredWaitInterval];

                self.retryCount++;
            }else{
                NSLog(@"<CLARABRIDGECHAT::ERROR> An unexpected error occurred during initialization. Retry attempts are exhausted. \nError: %@ \nResponse: %@ \n", [response.error localizedDescription], response.httpResponse);

                [self notifyInitializationFailedWithErrorCode:response.clbErrorCode statusCode:response.statusCode];
            }
        }
    }else{
        [self logPushTokenIfExists];
        self.validityStatus = CLBAppTokenStatusValid;

        CLBUser* user = self.userSynchronizer.user;
        [user deserialize:response.responseObject];
        // If the dev has set values that the server already has, remove them
        [user removeRedundancyFromLocalObject];
        [user storeLocalProperties];

        [self.userSynchronizer scheduleImmediately];

        if(!self.remoteSettings.hasIcon) {
            UIImage* appIcon = CLBGetLargestAppIcon();
            if(appIcon) {
                [self.synchronizer.apiClient uploadImage:appIcon url:@"/v1/init/icon" completion:nil];
            }
        }

        if(self.remoteSettings.pushEnabled){
            CLBEnsureMainThread(^{
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:CLBInitializationDidCompleteNotification object:nil];
    }
}

-(void)notifyInitializationFailedWithErrorCode:(NSString *)errorCode statusCode:(NSInteger) statusCode
{
    NSDictionary *userInfo = @{CLBErrorCodeIdentifier: errorCode ?: @"", CLBStatusCodeIdentifier: [NSNumber numberWithInteger:statusCode]};

    CLBEnsureMainThread(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBInitializationDidFailNotification object:nil userInfo:userInfo];
    });
}

-(void)logPushTokenIfExists
{
    NSString* pushToken = CLBGetPushNotificationDeviceToken();
    if(pushToken){
        NSLog(@"<CLARABRIDGECHAT::INFO> Push token successfully uploaded : %@", pushToken);
    }
}

@end
