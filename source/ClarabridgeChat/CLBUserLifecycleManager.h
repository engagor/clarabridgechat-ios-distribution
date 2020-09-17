//
//  CLBUserLifecycleManager.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CLBUser;
@class CLBDependencyManager;

@interface CLBUserLifecycleManager : NSObject

-(instancetype)initWithDependencyManager:(CLBDependencyManager *)depManager;

@property(readonly) BOOL isLoggedIn;

+(NSString*)lastKnownUserIdForAppId:(NSString*)appId;
+(NSString*)lastKnownJwtForAppId:(NSString*)appId;
+(NSString*)lastKnownAppUserIdForAppId:(NSString*)appId;
+(NSString*)lastKnownSessionTokenForAppId:(NSString*)appId;
+(void)setLastKnownJwt:(NSString*)jwt forAppId:(NSString*)appId;
+(void)setLastKnownUserId:(NSString*)userId forAppId:(NSString*)appId;
+(void)setLastKnownAppUserId:(NSString*)appUserId forAppId:(NSString*)appId;
+(void)setLastKnownSessionToken:(NSString*)sessionToken forAppId:(NSString*)appId;
+(void)clearUserIdForAppId:(NSString *)appId;
+(void)clearJwtForAppId:(NSString *)appId;
+(void)clearAppUserIdForAppId:(NSString *)appId;
+(void)clearSessionTokenForAppId:(NSString *)appId;

-(void)login:(NSString*)userId jwt:(NSString*)jwt completionHandler:(void(^)(NSError *error, NSDictionary *userInfo))handler;
-(void)logoutWithCompletionHandler:(void(^)(NSError *error, NSDictionary *userInfo))handler;
-(void)rebuildDependenciesWithUserId:(NSString *)userId jwt:(NSString *)jwt;
-(void)destroy;

@end
