//
//  CLBConversationListTableViewCell.h
//  ClarabridgeChat
//
//  Created by Conor Nolan on 20/05/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLBConversationViewModel.h"
#import "CLBImageLoader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CLBConversationListTableViewCell : UITableViewCell

@property (class, nonatomic, readonly) NSString *cellIdentifier;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier;

- (void)configureWithConversationViewModel:(CLBConversationViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
