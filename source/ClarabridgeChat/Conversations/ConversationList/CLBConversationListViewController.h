//
//  CLBConversationListViewController.h
//  ClarabridgeChat
//
//  Created by Thaciana Lima on 20/05/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLBConversationListDelegate.h"

@class CLBDependencyManager;
@protocol CLBUtilitySettings;

NS_ASSUME_NONNULL_BEGIN

@interface CLBConversationListViewController : UIViewController

@property (class, nonatomic, readonly) BOOL isConversationListShown;
@property (weak, nonatomic, nullable) id<CLBConversationListDelegate> delegate;

- (instancetype)initWithDeps:(CLBDependencyManager *)deps utilitySettings:(id<CLBUtilitySettings>)utilitySettings showCreateConversationButton:(BOOL)showCreateConversationButton;


@end

NS_ASSUME_NONNULL_END
