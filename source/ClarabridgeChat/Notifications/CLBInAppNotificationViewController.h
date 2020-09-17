//
//  CLBInAppNotificationViewController.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CLBMessage;
@class CLBConversation;
@protocol CLBInAppNotificationViewControllerDelegate;

@interface CLBInAppNotificationViewController : UIViewController

-(instancetype)initWithMessage:(CLBMessage*)message avatar:(UIImage*)avatarImage conversation:(CLBConversation*)conversation;
-(void)slideUpWithCompletion:(void (^)(void))completion;
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;

@property(nonatomic, weak) id<CLBInAppNotificationViewControllerDelegate> delegate;
@property CLBMessage* message;
@property CLBConversation* conversation;

@end

@protocol CLBInAppNotificationViewControllerDelegate <NSObject>

-(void)notificationViewControllerDidSelectNotification:(CLBInAppNotificationViewController*)viewController;
-(void)notificationViewControllerDidDismissNotification:(CLBInAppNotificationViewController*)viewController;

@end
