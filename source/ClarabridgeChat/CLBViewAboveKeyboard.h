//
//  CLBViewAboveKeyboard.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLBViewAboveKeyboard : UIView

-(void)reframeAnimated:(BOOL)animated;

@property BOOL cancelAnimations;
@property double keyboardAnimationDuration;
@property int keyboardAnimationCurve;

@end

@interface CLBViewAboveKeyboard(Overrides)

-(void)animateReframe:(CGFloat)keyboardHeight;
-(void)reframe:(CGFloat)keyboardHeight;
-(CGFloat)getKeyboardHeightWithOrientation:(UIInterfaceOrientation)orientation;
-(void)keyboardShown:(NSNotification*)notification;
-(void)keyboardHidden:(NSNotification*)notification;

@end
