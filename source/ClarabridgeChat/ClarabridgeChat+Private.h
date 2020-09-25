//
//  ClarabridgeChat+ClarabridgeChat_Private.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#ifdef DEBUG
#define CLBDebug NSLog
#else
#define CLBDebug(...) do { } while(0)
#endif

#import <ClarabridgeChat/ClarabridgeChat.h>
#import <UIKit/UIKit.h>
#import "CLBConversation.h"
@class CLBImageLoader;
@class CLBDependencyManager;
@class CLBUserLifecycleManager;

extern NSString* const CLBReachabilityStatusChangedNotification;

@interface ClarabridgeChat (Private)

// Actions
+(void)showConversationWithAction:(CLBAction)action info:(NSDictionary *)info;
+(void)showConversation:(CLBConversation*)conversation withAction:(CLBAction)action info:(NSDictionary *)info;
+(void)createAndPresentConversation:(UIViewController*)viewController;
+(void)sendImage:(UIImage *)image withMetadata:(NSDictionary*)metadata withProgress:(void (^)(double progress))progressBlock completion:(void (^)(NSError* error, NSDictionary* responseObject))completionBlock;
+(void)sendFile:(NSURL *)fileLocation withMetadata:(NSDictionary*)metadata withProgress:(void (^)(double progress))progressBlock completion:(void (^)(NSError* error, NSDictionary* responseObject))completionBlock;
+ (void)postback:(CLBMessageAction *)action toConversation:(CLBConversation *)conversation completion:(void (^)(NSError *error))completionBlock;
+(void)fetchConfig;

// Getters
+(BOOL)didBecomeActiveOnce;
+(BOOL)shouldSuppressInAppNotifs;
+(BOOL)wasLaunchedFromPushNotification;
+(NSBundle*)getResourceBundle;
+(UIImage*)getImageFromResourceBundle:(NSString*)imageName;
+(BOOL)isConversationShown;
+(CLBImageLoader*)avatarImageLoader;
+(id<UIApplicationDelegate>)clbAppDelegate;
+(id<CLBConversationDelegate>)conversationDelegate;
+(CLBDependencyManager*)dependencyManager;
+(BOOL)isUserLoggedIn;

+(void)setDependencyManager:(CLBDependencyManager*)newManager;
+(void)setUserLifecycleManager:(CLBUserLifecycleManager*)newManager;
+(CLBUserLifecycleManager*)getUserLifecycleManager;
+(void)setImageLoader:(CLBImageLoader*)imageLoader;
+(void)setDidBecomeActiveOnce:(BOOL)didBecomeActiveOnce;

+(void)startConversationWithIntent:(NSString*)intent completionHandler:(void (^)(NSError *error, NSDictionary *userInfo))completionHandler;
+(void)updateConversationId:(NSString *)conversationId;

+(BOOL)shouldShowConversationFromViewController;
+(BOOL)messagesAreTextOnly:(NSArray<CLBMessage *> *)messages;

@end
