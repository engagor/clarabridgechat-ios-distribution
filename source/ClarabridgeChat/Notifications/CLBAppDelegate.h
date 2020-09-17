//
//  CLBAppDelegate.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
@class CLBPushNotificationFilter;
@class CLBDependencyManager;

@interface CLBAppDelegate : NSObject < UIApplicationDelegate, UNUserNotificationCenterDelegate >

-(instancetype)initWithPushFilter:(CLBPushNotificationFilter*)pushFilter dependencyManager:(CLBDependencyManager*)dependencyManager;

@property CLBPushNotificationFilter* pushFilter;
@property id<UNUserNotificationCenterDelegate> otherNotificationCenterDelegate;

-(void)handleNotification:(NSDictionary*)userInfo;
-(void)handleUserNotificationActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler;
-(void)handleUserNotificationActionWithIdentifier:(NSString *)identifier withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler;
-(void)handleUserNotificationActionWithIdentifier:(NSString *)identifier withText:(NSString *)text completionHandler:(void (^)(void))completionHandler;

@end
