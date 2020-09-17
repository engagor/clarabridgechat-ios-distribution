//
//  UITextField+Shake.h
//  UITextField+Shake
//
//  Created by Andrea Mazzini on 08/02/14.
//  Copyright (c) 2015 Fancy Pixel. All rights reserved.
//

#import <UIKit/UIKit.h>

/** @enum ShakeDirection
 *
 * Enum that specifies the direction of the shake
 */
typedef NS_ENUM(NSInteger, CLBShakeDirection) {
    /** Shake left and right */
    CLBShakeDirectionHorizontal,
    /** Shake up and down */
    CLBShakeDirectionVertical
};

/**
 * @name UITextField+Shake
 * A UITextField category that add the ability to shake the component
 */
@interface CLBUITextFieldShake : NSObject

/** Shake the UITextField
 *
 * Shake the text field with default values
 */
+ (void)shake:(UIView*)view;

/** Shake the UITextField
 *
 * Shake the text field a given number of times
 *
 * @param times The number of shakes
 * @param delta The width of the shake
 */
+ (void)shake:(int)times withDelta:(CGFloat)delta view:(UIView*)view;

/** Shake the UITextField
 *
 * Shake the text field a given number of times
 *
 * @param times The number of shakes
 * @param delta The width of the shake
 * @param handler A block object to be executed when the shake sequence ends
 */
+ (void)shake:(int)times withDelta:(CGFloat)delta completion:(void (^)(void))handler view:(UIView*)view;

/** Shake the UITextField at a custom speed
 *
 * Shake the text field a given number of times with a given speed
 *
 * @param times The number of shakes
 * @param delta The width of the shake
 * @param interval The duration of one shake
 */
+ (void)shake:(int)times withDelta:(CGFloat)delta speed:(NSTimeInterval)interval view:(UIView*)view;

/** Shake the UITextField at a custom speed
 *
 * Shake the text field a given number of times with a given speed
 *
 * @param times The number of shakes
 * @param delta The width of the shake
 * @param interval The duration of one shake
 * @param handler A block object to be executed when the shake sequence ends
 */
+ (void)shake:(int)times withDelta:(CGFloat)delta speed:(NSTimeInterval)interval completion:(void (^)(void))handler view:(UIView*)view;

/** Shake the UITextField at a custom speed
 *
 * Shake the text field a given number of times with a given speed
 *
 * @param times The number of shakes
 * @param delta The width of the shake
 * @param interval The duration of one shake
 * @param direction of the shake
 */
+ (void)shake:(int)times withDelta:(CGFloat)delta speed:(NSTimeInterval)interval shakeDirection:(CLBShakeDirection)shakeDirection view:(UIView*)view;

/** Shake the UITextField at a custom speed
 *
 * Shake the text field a given number of times with a given speed
 *
 * @param times The number of shakes
 * @param delta The width of the shake
 * @param interval The duration of one shake
 * @param direction of the shake
 * @param handler A block object to be executed when the shake sequence ends
 */
+ (void)shake:(int)times withDelta:(CGFloat)delta speed:(NSTimeInterval)interval shakeDirection:(CLBShakeDirection)shakeDirection completion:(void (^)(void))handler view:(UIView*)view;

@end
