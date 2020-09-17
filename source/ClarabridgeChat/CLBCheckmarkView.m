//
//  CLBCheckmarkLayer.m
//  ClarabridgeChat
//
//  Copyright © 2015 Radialpoint. All rights reserved.
//

#import "CLBCheckmarkView.h"

static const CGFloat kLineWidth = 2;

static const CGFloat kFinalStrokeEndForCheckmark = 0.85;
static const CGFloat kFinalStrokeStartForCheckmark = 0.3;

@interface CLBCheckmarkView()

@property CGPoint checkmarkMidPoint;
@property CAShapeLayer* checkmark;

@end


// Translated to Objective-C from https://github.com/cocoatoucher/AIFlatSwitch/blob/master/Source/AIFlatSwitch.swift
@implementation CLBCheckmarkView

-(instancetype)init {
    self = [super init];
    if(self){
        self.checkmark = [CAShapeLayer layer];
        self.checkmark.lineJoin = kCALineJoinRound;
        self.checkmark.lineCap = kCALineCapRound;
        self.checkmark.lineWidth = kLineWidth;
        self.checkmark.fillColor = [UIColor clearColor].CGColor;
        self.checkmark.strokeColor = [UIColor whiteColor].CGColor;

        self.checkmark.strokeEnd = kFinalStrokeEndForCheckmark;
        self.checkmark.strokeStart = kFinalStrokeStartForCheckmark;
        [self.layer addSublayer:self.checkmark];
    }
    return self;
}

-(void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    if(layer == self.layer){
        CGPoint offset = CGPointZero;
        CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) / 2 - 1;
        offset.x = (self.bounds.size.width - radius * 2) / 2.0;
        offset.y = (self.bounds.size.height - radius * 2) / 2.0;

        [CATransaction begin];
        [CATransaction setDisableActions:true];

        CGPoint origin = CGPointMake(offset.x + radius, offset.y + radius);
        CGPoint checkStartPoint = CGPointZero;
        checkStartPoint.x = origin.x + radius * (CGFloat)(cos(212 * M_PI / 180));
        checkStartPoint.y = origin.y + radius * (CGFloat)(sin(212 * M_PI / 180));

        UIBezierPath* checkmarkPath = [[UIBezierPath alloc] init];
        [checkmarkPath moveToPoint:checkStartPoint];

        self.checkmarkMidPoint = CGPointMake(offset.x + radius * 0.9, offset.y + radius * 1.4);
        [checkmarkPath addLineToPoint:self.checkmarkMidPoint];

        CGPoint checkEndPoint = CGPointZero;
        checkEndPoint.x = origin.x + radius * (CGFloat)(cos(320 * M_PI / 180));
        checkEndPoint.y = origin.y + radius * (CGFloat)(sin(320 * M_PI / 180));

        [checkmarkPath addLineToPoint:checkEndPoint];

        self.checkmark.frame = self.bounds;
        self.checkmark.path = checkmarkPath.CGPath;

        [CATransaction commit];
    }
}

@end
