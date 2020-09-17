//
//  CLBInAppNotificationView.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CLBMessage;

extern const CGFloat CLBInAppNotificationViewHeight;

@interface CLBInAppNotificationView : UIView

-(instancetype)initWithMessage:(CLBMessage*)message avatar:(UIImage*)avatarImage target:(id)target action:(SEL)action;

-(void)animateAvatarAndLabel;

@end
