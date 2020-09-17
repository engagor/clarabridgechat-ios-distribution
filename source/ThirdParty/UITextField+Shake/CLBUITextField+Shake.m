//
//  UITextField+Shake.m
//  UITextField+Shake
//
//  Created by Andrea Mazzini on 08/02/14.
//  Copyright (c) 2015 Fancy Pixel. All rights reserved.
//

#import "CLBUITextField+Shake.h"

@implementation CLBUITextFieldShake

+ (void)shake:(UIView*)view {
    [self shake:10 withDelta:5 completion:nil view:view];
}

+ (void)shake:(int)times withDelta:(CGFloat)delta view:(UIView*)view {
    [self shake:times withDelta:delta completion:nil view:view];
}

+ (void)shake:(int)times withDelta:(CGFloat)delta completion:(void (^)(void))handler view:(UIView*)view {
    [self _shake:times direction:1 currentTimes:0 withDelta:delta speed:0.03 shakeDirection:CLBShakeDirectionHorizontal completion:handler view:view];
}

+ (void)shake:(int)times withDelta:(CGFloat)delta speed:(NSTimeInterval)interval view:(UIView*)view {
    [self shake:times withDelta:delta speed:interval completion:nil view:view];
}

+ (void)shake:(int)times withDelta:(CGFloat)delta speed:(NSTimeInterval)interval completion:(void (^)(void))handler view:(UIView*)view {
    [self _shake:times direction:1 currentTimes:0 withDelta:delta speed:interval shakeDirection:CLBShakeDirectionHorizontal completion:handler view:view];
}

+ (void)shake:(int)times withDelta:(CGFloat)delta speed:(NSTimeInterval)interval shakeDirection:(CLBShakeDirection)shakeDirection view:(UIView*)view {
    [self shake:times withDelta:delta speed:interval shakeDirection:shakeDirection completion:nil view:view];
}

+ (void)shake:(int)times withDelta:(CGFloat)delta speed:(NSTimeInterval)interval shakeDirection:(CLBShakeDirection)shakeDirection completion:(void (^)(void))handler view:(UIView*)view {
    [self _shake:times direction:1 currentTimes:0 withDelta:delta speed:interval shakeDirection:shakeDirection completion:handler view:view];
}

+ (void)_shake:(int)times direction:(int)direction currentTimes:(int)current withDelta:(CGFloat)delta speed:(NSTimeInterval)interval shakeDirection:(CLBShakeDirection)shakeDirection completion:(void (^)(void))handler view:(UIView*)view {
    [UIView animateWithDuration:interval animations:^{
        view.transform = (shakeDirection == CLBShakeDirectionHorizontal) ? CGAffineTransformMakeTranslation(delta * direction, 0) : CGAffineTransformMakeTranslation(0, delta * direction);
    } completion:^(BOOL finished) {
        if(current >= times) {
            [UIView animateWithDuration:interval animations:^{
                view.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                if (handler) {
                    handler();
                }
            }];
            return;
        }
        [self _shake:(times - 1)
           direction:direction * -1
        currentTimes:current + 1
           withDelta:delta
               speed:interval
      shakeDirection:shakeDirection
          completion:handler
                view:view];
    }];
}

@end
