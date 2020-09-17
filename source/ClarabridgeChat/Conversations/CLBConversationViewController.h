//
//  CLBConversationViewController.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBSOMessagingViewController.h"
@class CLBDependencyManager;
@protocol CLBConversationViewControllerDelegate;

@interface CLBConversationViewController : CLBSOMessagingViewController

@property (weak) id<CLBConversationViewControllerDelegate> delegate;

- (instancetype)initWithDeps:(CLBDependencyManager *)deps;

+ (BOOL)isConversationShown;
- (void)updateConversationId:(NSString *)conversationId;

@end
