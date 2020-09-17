//
//  CLBDependencyManager+Private.h
//  ClarabridgeChat
//
//  Created by Alan O'Connor on 28/01/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBDependencyManager.h"

@class CLBConversationController, CLBConversationViewController, CLBMessage;

@interface CLBDependencyManager(Private)

@property CLBConversationController *conversationController;
@property CLBConversationViewController *conversationViewController;

- (void)handleSendPendingMessage:(CLBMessage *)message conversationId:(NSString *)conversationId;
- (void)handleUpdatedSettings;

@end
