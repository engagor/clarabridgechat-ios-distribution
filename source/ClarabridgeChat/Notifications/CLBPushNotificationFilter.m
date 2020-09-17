//
//  CLBPushNotificationFilter.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBPushNotificationFilter.h"
#import "ClarabridgeChat.h"
#import <UserNotifications/UserNotifications.h>

@implementation CLBPushNotificationFilter

-(BOOL)isClarabridgeChatNotification:(NSDictionary *)userInfo {
    return userInfo[CLBPushNotificationIdentifier] != nil;
}

-(BOOL)isRemoteNotification:(UNNotification*)notification {
    return notification.request.trigger && [notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]];
}

@end
