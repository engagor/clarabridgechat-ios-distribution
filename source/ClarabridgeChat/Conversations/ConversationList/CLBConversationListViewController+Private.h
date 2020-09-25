//
//  CLBConversationListViewController+Private.h
//  ClarabridgeChat
//
//  Created by Thaciana Lima on 11/08/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBConversationListViewController.h"

@class CLBConversationController;

NS_ASSUME_NONNULL_BEGIN

@interface CLBConversationListViewController (Private)

- (void)conversationDidLoad:(NSString *)conversationId conversationController:(CLBConversationController *)conversationController;

@end

NS_ASSUME_NONNULL_END
