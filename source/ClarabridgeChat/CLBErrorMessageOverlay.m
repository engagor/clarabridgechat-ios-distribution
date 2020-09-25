//
//  CLBNoNetworkOverlay.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBErrorMessageOverlay.h"
#import "CLBLocalization.h"

static const CGFloat kMinHeight = 30;

@implementation CLBErrorMessageOverlay

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];

        UILabel *textLabel = [[UILabel alloc] init];
        _textLabel = textLabel;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.numberOfLines = 2;
        _textLabel.font = [UIFont systemFontOfSize:13];
        [self addSubview:_textLabel];
    }
    return self;
}

- (instancetype)initWithConstraints {
    self = [self initWithFrame:CGRectZero];
    if (self) {
        [self setHidden:YES];
        self.alpha = 0.0;
        _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[[_textLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                  [_textLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                                  [self.trailingAnchor constraintEqualToAnchor:_textLabel.trailingAnchor],
                                                  [self.bottomAnchor constraintEqualToAnchor:_textLabel.bottomAnchor],
                                                  [_textLabel.heightAnchor constraintGreaterThanOrEqualToConstant:kMinHeight]]];
    }
    return self;
}

- (void)showWithText:(NSString *)text animated:(BOOL)animated {
    [self showWithText:text button:nil animated:animated];
}

- (void)showWithText:(NSString *)text button:(UIButton *)actionButton animated:(BOOL)animated {
    self.textLabel.text = text;

    if (self.actionButton) {
        [self.actionButton removeFromSuperview];
    }
    if (actionButton) {
        actionButton.translatesAutoresizingMaskIntoConstraints = NO;
        actionButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [actionButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [self addSubview:actionButton];

        [NSLayoutConstraint activateConstraints:@[
            [actionButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-15],
            [actionButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]]];

        self.actionButton = actionButton;
    }

    if (self.isHidden) {
        if (animated) {
            [self setHidden:NO];
            [UIView animateWithDuration:0.3 animations:^{
                self.alpha = 1.0;
            } completion:^(BOOL finished) {
                [self.delegate errorMessageOverlay:self changedWithIsHidden:NO animated:YES];
            }];
        } else {
            [self setHidden:NO];
            self.alpha = 1.0;
            [self.delegate errorMessageOverlay:self changedWithIsHidden:NO animated:NO];
        }
    } else {
        if (animated) {
            [UIView animateWithDuration:0.6 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                [UIView setAnimationRepeatCount:1];
                self.alpha = 0.0;
                self.alpha = 1.0;
            } completion:nil];
        }
    }
}

- (void)hideAnimated:(BOOL)animated {
    if (self.isHidden) { return; }
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished){
            [self setHidden:YES];
            [self.delegate errorMessageOverlay:self changedWithIsHidden:YES animated:YES];
        }];
    } else {
        self.alpha = 0.0;
        [self setHidden:YES];
        [self.delegate errorMessageOverlay:self changedWithIsHidden:YES animated:NO];
    }
}

- (void)sizeToFit {
    CGSize maxSize = [self.textLabel sizeThatFits:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)];
    self.textLabel.frame = CGRectMake(0, 0, self.bounds.size.width, MAX(maxSize.height, kMinHeight));

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.textLabel.frame.size.height);
}

@end
