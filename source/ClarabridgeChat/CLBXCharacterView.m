//
//  CLBXCharacterView.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBXCharacterView.h"
#import "CLBInAppNotificationView.h"

const double thickness = 1;

@implementation CLBXCharacterView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIColor* lineColor = [UIColor colorWithRed:145.0f/255.0f
                                         green:145.0f/255.0f
                                          blue:145.0f/255.0f
                                         alpha:1.0f];;

        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(0, 0)];
        [path addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];

        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [path CGPath];
        shapeLayer.strokeColor = [lineColor CGColor];;
        shapeLayer.lineWidth = thickness;
        shapeLayer.fillColor = [[UIColor clearColor] CGColor];

        [self.layer addSublayer:shapeLayer];

        [path moveToPoint:CGPointMake(0, self.frame.size.height)];
        [path addLineToPoint:CGPointMake(self.frame.size.width, 0)];
        shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [path CGPath];
        shapeLayer.strokeColor = [lineColor CGColor];
        shapeLayer.lineWidth = thickness;
        shapeLayer.fillColor = [[UIColor clearColor] CGColor];

        [self.layer addSublayer:shapeLayer];

    }
    return self;
}

@end
