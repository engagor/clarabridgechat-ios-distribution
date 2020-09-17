//
//  CLBInAppNotificationHandler.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CLBMessage;
@class CLBSettings;
@class CLBConversation;
@class UNUserNotificationCenter;

@interface CLBInAppNotificationHandler : NSObject

- (instancetype)initWithSettings:(CLBSettings *)settings
          userNotificationCenter:(UNUserNotificationCenter *)userNotificationCenter
                    conversation:(CLBConversation *)conversation;

- (BOOL)shouldShowInAppNotification:(CLBMessage *)message conversation:(CLBConversation*)conversation;
- (void)showInAppNotification:(CLBMessage *)message conversation:(CLBConversation*)conversation;

@end
