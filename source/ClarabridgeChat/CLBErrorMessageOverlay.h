//
//  CLBNoNetworkOverlay.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CLBErrorMessageOverlay;

@protocol CLBErrorMessageOverlayDelegate <NSObject>

- (void)errorMessageOverlay:(CLBErrorMessageOverlay *)errorMessageOverlay changedWithIsHidden:(BOOL)isHidden animated:(BOOL)animated;

@end

@interface CLBErrorMessageOverlay : UIView

@property (nonatomic, weak) UILabel *textLabel;
@property (nonatomic, weak) id<CLBErrorMessageOverlayDelegate> delegate;
@property (nonatomic, weak) UIButton *actionButton;

/// Initializes an CLBErrorMessageOverlay using constraints and starting with hidden state.
/// Call `showWithText:(NSString *)text animated:(BOOL)animated` and `hideAnimated:(BOOL)animated` to show and hide the message.
- (instancetype)initWithConstraints;

- (void)sizeToFit;

- (void)showWithText:(NSString *)text animated:(BOOL)animated;
- (void)showWithText:(NSString *)text button:(UIButton *)actionButton animated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;

@end
