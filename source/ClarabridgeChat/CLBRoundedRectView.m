//
//  CLBRoundedRectView.m
//  ClarabridgeChat
//
//  Copyright © 2016 Radialpoint. All rights reserved.
//

#import "CLBRoundedRectView.h"

static const CGFloat kCornerRadius = 14;
static const CGFloat kFlatCornerRadius = 4;

@interface CLBRoundedRectView()

@property UIView* straightCornerView;

@end

@implementation CLBRoundedRectView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        _straightCornerView = [[UIView alloc] init];
        _straightCornerView.layer.cornerRadius = kFlatCornerRadius;
        [self addSubview:_straightCornerView];

        self.layer.cornerRadius = kCornerRadius;
    }
    return self;
}

-(void)setFlatCorners:(CLBCorners)flatCorners {
    if(flatCorners != _flatCorners){
        _flatCorners = flatCorners;
        [self layoutFlatCorners];
    }
}

-(void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    [self.straightCornerView setBackgroundColor:backgroundColor];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    [self layoutFlatCorners];
}

-(void)layoutFlatCorners {
    // Valid combinations are :
    // * any single corner
    // * any two corners on the same side (left or right)
    CGRect frame = CGRectZero;

    CGFloat cornerRadius = kCornerRadius;
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;

    BOOL topLeft = (self.flatCorners & CLBCornerTopLeft) > 0;
    BOOL bottomLeft = (self.flatCorners & CLBCornerBottomLeft) > 0;
    BOOL topRight = (self.flatCorners & CLBCornerTopRight) > 0;
    BOOL bottomRight = (self.flatCorners & CLBCornerBottomRight) > 0;

    if (topLeft && bottomLeft && topRight && bottomRight) {
        frame.size.width = width;
        frame.size.height = height;
    }else if(topLeft || bottomLeft){
        frame.size.width = cornerRadius;

        if(topLeft && bottomLeft){
            frame.size.height = height;
        }else if(topLeft){
            frame.size.height = cornerRadius;
        }else{
            frame.size.height = cornerRadius;
            frame.origin.y = height - cornerRadius;
        }
    }else if(topRight || bottomRight){
        frame.size.width = cornerRadius;
        frame.origin.x = width - cornerRadius;

        if(topRight && bottomRight){
            frame.size.height = height;
        }else if(topRight){
            frame.size.height = cornerRadius;
        }else{
            frame.size.height = cornerRadius;
            frame.origin.y = height - cornerRadius;
        }
    }

    self.straightCornerView.frame = frame;
}

@end
