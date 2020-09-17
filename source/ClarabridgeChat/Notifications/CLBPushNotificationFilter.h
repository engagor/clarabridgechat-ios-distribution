//
//  CLBPushNotificationFilter.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UNNotification;

@interface CLBPushNotificationFilter : NSObject

-(BOOL)isClarabridgeChatNotification:(NSDictionary*)userInfo;
-(BOOL)isRemoteNotification:(UNNotification*)notification;

@end
