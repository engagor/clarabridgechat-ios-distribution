//
//  CLBUserLifecycleManager.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBUserLifecycleManager.h"
#import "CLBDependencyManager+Private.h"
#import "CLBSettings+Private.h"
#import "CLBUser+Private.h"
#import "CLBConversation+Private.h"
#import "CLBConfigFetchScheduler.h"
#import "CLBConversationMonitor.h"
#import "CLBUserSynchronizer.h"
#import "CLBRemoteObjectSynchronizer.h"
#import "ClarabridgeChat+Private.h"
#import "CLBUtility.h"
#import "CLBUserLifecycleManager.h"
#import "CLBPersistence.h"
#import "CLBConversationStorageManager.h"

static NSString* const kUserIdDefaultsKey = @"CLARABRIDGECHAT_LAST_KNOWN_USER_ID";
static NSString* const kAppUserIdDefaultsKey = @"CLARABRIDGECHAT_LAST_KNOWN_APP_USER_ID";
static NSString* const kJwtDefaultsKey = @"CLARABRIDGECHAT_LAST_KNOWN_JWT";
static NSString* const kSessionTokenDefaultsKey = @"CLARABRIDGECHAT_LAST_KNOWN_SESSION_TOKEN";

@interface CLBUserLifecycleManager()

@property CLBDependencyManager* depManager;

@end

@implementation CLBUserLifecycleManager

# pragma mark - UserId Storage

+(NSString*)userIdKeyForAppId:(NSString*)appId {
    return [NSString stringWithFormat:@"%@_%@", kUserIdDefaultsKey, appId];
}

+(NSString*)lastKnownUserIdForAppId:(NSString*)appId {
    return [[CLBPersistence sharedPersistence] getValueFromUserDefaults:[self userIdKeyForAppId:appId]];
}

+(void)setLastKnownUserId:(NSString*)userId forAppId:(NSString*)appId {
    [[CLBPersistence sharedPersistence] persistValue:userId inUserDefaults:[self userIdKeyForAppId:appId]];
}

+(void)clearUserIdForAppId:(NSString *)appId {
    [[CLBPersistence sharedPersistence] removeValueFromUserDefaults:[self userIdKeyForAppId:appId]];
}

# pragma mark - JWT Storage

+(NSString*)jwtKeyForAppId:(NSString*)appId {
    return [NSString stringWithFormat:@"%@_%@", kJwtDefaultsKey, appId];
}

+(NSString*)lastKnownJwtForAppId:(NSString*)appId {
    NSString* key = [self jwtKeyForAppId:appId];
    NSString* jwt = [[CLBPersistence sharedPersistence] getValueFromKeychain:key];
    
    if (!jwt || jwt.length == 0) {
        jwt = [[CLBPersistence sharedPersistence] getValueFromUserDefaults:key];
        
        if (jwt && jwt.length > 0) {
            // Back compat. Upgrade jwt in user defaults to use keychain instead
            [[CLBPersistence sharedPersistence] removeValueFromUserDefaults:key];
            [[CLBPersistence sharedPersistence] persistValue:jwt inKeychain:key];
        }
    }
    
    return jwt;
}

+(void)setLastKnownJwt:(NSString*)jwt forAppId:(NSString*)appId {
    [[CLBPersistence sharedPersistence] persistValue:jwt inKeychain:[self jwtKeyForAppId:appId]];
}

+(void)clearJwtForAppId:(NSString *)appId {
    NSString* key = [self jwtKeyForAppId:appId];
    
    [[CLBPersistence sharedPersistence] removeValueFromKeychain:key];
    
    // Back compat. Jwts used to be stored in user defaults
    [[CLBPersistence sharedPersistence] removeValueFromUserDefaults:key];
}

# pragma mark - appUserId Storage

+(NSString*)appUserIdKeyForAppId:(NSString*)appId {
    return [NSString stringWithFormat:@"%@_%@", kAppUserIdDefaultsKey, appId];
}

+(NSString*)lastKnownAppUserIdForAppId:(NSString*)appId {
    return [[CLBPersistence sharedPersistence] getValueFromUserDefaults:[self appUserIdKeyForAppId:appId]];
}

+(void)setLastKnownAppUserId:(NSString*)appUserId forAppId:(NSString*)appId {
    [[CLBPersistence sharedPersistence] persistValue:appUserId inUserDefaults:[self appUserIdKeyForAppId:appId]];
}

+(void)clearAppUserIdForAppId:(NSString *)appId {
    [[CLBPersistence sharedPersistence] removeValueFromUserDefaults:[self appUserIdKeyForAppId:appId]];
}

# pragma mark - sessionToken Storage

+(NSString*)sessionTokenKeyForAppId:(NSString*)appId {
    return [NSString stringWithFormat:@"%@_%@", kSessionTokenDefaultsKey, appId];
}

+(NSString*)lastKnownSessionTokenForAppId:(NSString*)appId {
    NSString* key = [self sessionTokenKeyForAppId:appId];
    NSString* sessionToken = [[CLBPersistence sharedPersistence] getValueFromKeychain:key];
    
    if (!sessionToken || sessionToken.length == 0) {
        sessionToken = [[CLBPersistence sharedPersistence] getValueFromUserDefaults:key];
        
        if (sessionToken && sessionToken.length > 0) {
            // Back compat. Upgrade session token in user defaults to use keychain instead
            [[CLBPersistence sharedPersistence] removeValueFromUserDefaults:key];
            [[CLBPersistence sharedPersistence] persistValue:sessionToken inKeychain:key];
        }
    }

    return sessionToken;
}

+(void)setLastKnownSessionToken:(NSString *)token forAppId:(NSString *)appId {
    [[CLBPersistence sharedPersistence] persistValue:token inKeychain:[self sessionTokenKeyForAppId:appId]];
}

+(void)clearSessionTokenForAppId:(NSString *)appId {
    NSString* key = [self sessionTokenKeyForAppId:appId];
    
    [[CLBPersistence sharedPersistence] removeValueFromKeychain:key];
    
    // Back compat. Session tokens used to be stored in user defaults
    [[CLBPersistence sharedPersistence] removeValueFromUserDefaults:key];
}

# pragma mark - Instance methods

-(instancetype)initWithDependencyManager:(CLBDependencyManager *)depManager {
    self = [super init];
    if(self){
        _depManager = depManager;
    }
    return self;
}

-(BOOL)isLoggedIn {
    return self.depManager.sdkSettings.userId.length > 0 && self.depManager.sdkSettings.jwt.length > 0;
}

-(BOOL)appDidBecomeActiveOnce {
    return [ClarabridgeChat didBecomeActiveOnce];
}

-(void)rebuildDependenciesWithUserId:(NSString *)userId jwt:(NSString *)jwt {
    CLBSettings* settings = self.depManager.sdkSettings;
    settings.userId = userId;
    settings.jwt = jwt;

    id<CLBConversationDelegate> convoDelegate = self.depManager.conversation.delegate;
    BOOL initializationComplete = self.depManager.configFetchScheduler.isInitializationComplete;

    [self destroy];

    [self.depManager createObjectsWithSettings:settings config:self.depManager.config];
    [CLBUser setCurrentUser:self.depManager.userSynchronizer.user];
    self.depManager.conversation.delegate = convoDelegate;
    self.depManager.configFetchScheduler.isInitializationComplete = initializationComplete;
}

-(void)login:(NSString*)userId jwt:(NSString*)jwt completionHandler:(void (^)(NSError *, NSDictionary *))handler {
    CLBConfigFetchScheduler* outgoingScheduler = self.depManager.configFetchScheduler;
    CLBRemoteObjectSynchronizer* outgoingSynchronizer = outgoingScheduler.synchronizer;
    CLBUser* outgoingUser = self.depManager.userSynchronizer.user;

    [self rebuildDependenciesWithUserId:userId jwt:jwt];
    CLBUserSynchronizer *userSynchronizer = self.depManager.userSynchronizer;

    void (^loginCompletionHandler)(NSError *, NSDictionary *) = ^(NSError *error, NSDictionary *userInfo){
        if (!error) {
            if (self.depManager.config.isAppActive) {
                self.depManager.config.validityStatus = CLBAppStatusValid;
            }
            
            CLBEnsureMainThread(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:CLBLoginDidCompleteNotification object:nil userInfo:userInfo];
            });
        } else {
            CLBEnsureMainThread(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:CLBLoginDidFailNotification object:nil userInfo:userInfo];
            });
        }

        if (handler) {
            CLBEnsureMainThread(^{
                handler(error, userInfo);
            });
        }
    };
    
    if(outgoingScheduler.config.validityStatus == CLBAppStatusValid && outgoingUser.appUserId && outgoingUser.isModified){
        // Flush user props to the server before switching users
        [outgoingSynchronizer synchronize:outgoingUser completion:^(CLBRemoteResponse *response) {
            [userSynchronizer logInWithCompletionHandler:loginCompletionHandler];
        }];
    } else {
        if([self appDidBecomeActiveOnce]){
            [userSynchronizer logInWithCompletionHandler:loginCompletionHandler];
        }
    }
}

-(void)logoutWithCompletionHandler:(void(^)(NSError *, NSDictionary *))handler {
    CLBUser *user = self.depManager.userSynchronizer.user;
    BOOL userExists = user.appUserId != nil && user.appUserId.length > 0;
    
    void(^logoutCompletionBlock)(NSError *, NSDictionary *) = ^(NSError *error, NSDictionary *userInfo) {
        if (!error) {
            [self.depManager.conversation removeFromDisk];
            [[self class] clearAppUserIdForAppId:self.depManager.sdkSettings.appId];
            [[self class] clearSessionTokenForAppId:self.depManager.sdkSettings.appId];
            [[self class] clearUserIdForAppId:self.depManager.sdkSettings.appId];
            [[self class] clearJwtForAppId:self.depManager.sdkSettings.appId];
            [self rebuildDependenciesWithUserId:nil jwt:nil];
            CLBEnsureMainThread(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:CLBLogoutDidCompleteNotification object:nil];
            });
        } else {
            CLBEnsureMainThread(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:CLBLogoutDidFailNotification object:nil userInfo:userInfo];
            });
        }
        
        if (handler) {
            CLBEnsureMainThread(^{
                handler(error, userInfo);
            });
        }
    };
    
    if (userExists) {
        [self.depManager.userSynchronizer logOutWithCompletionHandler:logoutCompletionBlock];
    } else {
        logoutCompletionBlock(nil, nil);
    }
}

-(void)destroy {
    [self.depManager.conversationStorageManager clearStorage];
    [self.depManager.conversationMonitor disconnect];
    [self.depManager.configFetchScheduler destroy];
    [self.depManager.userSynchronizer destroy];
    self.depManager.conversationViewController = nil;

    [[CLBPersistence sharedPersistence] ensureProtectedDataAvailable:^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLBUserNSUserDefaultsKey];
    }];
}

@end
