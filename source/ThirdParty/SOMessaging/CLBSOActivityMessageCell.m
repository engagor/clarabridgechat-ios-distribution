//
//  CLBSOActivityMessageCell.m
//  ClarabridgeChat
//
//  Created by Will Mora on 2016-11-17.
//  Copyright © 2016 Radialpoint. All rights reserved.
//

#import "CLBSOActivityMessageCell.h"
#import "CLBRoundedRectView.h"
#import "CLBUtility.h"

static const CGFloat kHorizontalPadding = 10;
static const CGFloat kCircleSize = 8;
static const UIEdgeInsets CLBSOMessageCellActivityViewPadding = { 9, 9, 9, 9 };

@interface CLBSOActivityMessageCell()

@property NSArray *circles;

@end

@implementation CLBSOActivityMessageCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.circles = @[[self circleView], [self circleView], [self circleView]];
        
        for (UIView *circleView in self.circles) {
            [self.containerView addSubview:circleView];
        }
        
        [self animateView];
    }
    
    return self;
}

-(UIView *)circleView {
    UIView *circleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kCircleSize, kCircleSize)];
    circleView.layer.cornerRadius = kCircleSize / 2;
    circleView.layer.masksToBounds = YES;
    circleView.layer.backgroundColor = CLBLightGrayColor().CGColor;
    
    return circleView;
}

-(void)prepareForReuse {
    [super prepareForReuse];
    [self animateView];
}

-(void)animateView {
    for (int i = 0; i < self.circles.count; i++) {
        [self animateView:self.circles[i] withOffset:i];
    }
}

-(void)animateView:(UIView *)view withOffset:(NSInteger)offset {
    view.alpha = 0;
    [UIView animateWithDuration:.5 delay:0.25 * offset
                        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationCurveEaseInOut
                     animations:^{
                         view.alpha = 1;
                     }
                     completion:nil];
}

-(void)layoutContent {
    CGFloat width = self.circles.count * kCircleSize + kUserImageViewRightMargin;
    
    CGRect frame = CGRectMake(kHorizontalPadding, CLBSOMessageCellActivityViewPadding.top, width, kCircleSize * 2);
    
    frame.origin.x += kUserImageViewRightMargin + self.userImageViewSize.width;
    
    frame.origin.x += self.contentInsets.left - self.contentInsets.right;
    
    [self layoutBubble:frame];
    
    CGFloat y = frame.size.height * 7 / 8;
    
    for (int i = 0; i < self.circles.count; i++) {
        UIView *circleView = self.circles[i];
        CGFloat xOffset = i * (kCircleSize * 1.25);
        circleView.frame = CGRectMake(frame.origin.x + xOffset, y, kCircleSize, kCircleSize);
    }
}

-(void)layoutBubble:(CGRect)contentFrame {
    CGRect balloonFrame = CGRectZero;
    balloonFrame.size.width = contentFrame.size.width + 2* kHorizontalPadding;
    balloonFrame.size.height = CGRectGetMaxY(contentFrame) + CLBSOMessageCellActivityViewPadding.bottom;
    balloonFrame.origin.y = 0;
    
    if (self.userImage) {
        balloonFrame.origin.x = kUserImageViewRightMargin + self.userImageViewSize.width;
    }
    
    if (!CGSizeEqualToSize(self.userImageViewSize, CGSizeZero) && self.userImage) {
        if (balloonFrame.size.height < self.userImageViewSize.height) {
            balloonFrame.size.height = self.userImageViewSize.height;
        }
    }
    
    self.bubbleView.frame = balloonFrame;
}

@end
