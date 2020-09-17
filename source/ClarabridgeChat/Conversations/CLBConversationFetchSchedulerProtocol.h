//
//  CLBConversationFetchSchedulerProtocol.h
//  ClarabridgeChat
//
//  Created by Shona Nunez on 15/01/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class CLBMessage, CLBConversation;

@protocol CLBConversationFetchSchedulerProtocol <NSObject>

- (void)showInAppNotificationForMessage:(CLBMessage *)message conversation:(CLBConversation *)conversation;

@end

NS_ASSUME_NONNULL_END

