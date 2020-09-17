//
//  CLBMessageItemView.h
//  ClarabridgeChatTests
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLBRoundedRectView.h"
#import "CLBMessageItemViewModel.h"
#import "CLBMessageAction.h"

@class CLBMessageItemView;

@protocol CLBMessageItemViewDelegate <NSObject>

-(void)messageItemView:(CLBMessageItemView *)view didSelectAction:(CLBMessageAction *)action;
-(void)messageItemView:(CLBMessageItemView *)view didTapImage:(UIImage *)image;

@end

@interface CLBMessageItemView : UIView

@property (readonly) UIImageView *imageView;
@property (weak) id<CLBMessageItemViewDelegate> delegate;
@property (readonly) CLBMessageItemViewModel *viewModel;

-(void)setContent:(CLBMessageItemViewModel *)viewModel;
-(void)loadImage;

@end
