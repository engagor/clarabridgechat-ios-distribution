//
//  CLBProgressButton.m
//  ClarabridgeChat
//
//  Copyright © 2015 Radialpoint. All rights reserved.
//

#import "CLBProgressButton.h"
#import "CLBLocalization.h"
#import "CLBCheckmarkView.h"

@interface CLBProgressButton()

@property UIActivityIndicatorView* activityIndicator;
@property CLBCheckmarkView* checkmarkView;

@end

@implementation CLBProgressButton

-(instancetype)initWithFrame:(CGRect)frame activityIndicatorStyle:(UIActivityIndicatorViewStyle)style {
    self = [super initWithFrame:frame];
    if(self){
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        [self addSubview:_activityIndicator];
        
        _checkmarkView = [[CLBCheckmarkView alloc] init];
        _checkmarkView.hidden = YES;
        _checkmarkView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:_checkmarkView];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame activityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
}

-(void)layoutSubviews {
    [super layoutSubviews];

    self.activityIndicator.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

-(void)setShown:(BOOL)shown {
    if(shown && !_shown){
        _shown = YES;
        self.transform = CGAffineTransformMakeTranslation(0, 20);

        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformIdentity;
            self.alpha = 1.0;
        }];
    }else if(!shown && _shown){
        _shown = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformMakeTranslation(0, 20);
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.transform = CGAffineTransformIdentity;
        }];
    }
}

-(void)setProcessing:(BOOL)processing {
    CGPoint center = self.center;
    CGFloat diameter = self.bounds.size.height;
    CGFloat radius = diameter / 2;

    if (processing) {
        self.activityIndicator.transform = CGAffineTransformMakeScale(0, 0);
        [self.activityIndicator startAnimating];
        self.titleLabel.alpha = 0.0;

        [UIView animateWithDuration:0.2 animations:^{
            if (self.shrinkOnProcessing) {
                self.frame = CGRectMake(center.x - radius, center.y - radius, diameter, diameter);
            }

            self.activityIndicator.transform = CGAffineTransformIdentity;
        }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            [self.activityIndicator stopAnimating];
            self.titleLabel.alpha = 1.0;
        }];
    }
}

-(void)setCompleted {
    self.checkmarkView.transform = CGAffineTransformMakeScale(0, 0);
    self.checkmarkView.hidden = NO;

    [UIView animateWithDuration:0.3
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         self.activityIndicator.transform = CGAffineTransformMakeScale(0, 0);
                         self.checkmarkView.transform = CGAffineTransformIdentity;
                     } completion:nil];
}

-(void)resetToWidth:(CGFloat)width {
    CGPoint center = self.center;

    [UIView animateWithDuration:0.15 animations:^{
        self.frame = CGRectMake(center.x - width / 2, center.y - self.bounds.size.height / 2, width, self.bounds.size.height);
        self.activityIndicator.transform = CGAffineTransformMakeScale(0, 0);
    } completion:^(BOOL finished) {
        self.titleLabel.alpha = 1.0;
        [self.activityIndicator stopAnimating];
    }];
}

@end
