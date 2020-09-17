//
//  CLBInAppNotificationViewController.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBInAppNotificationViewController.h"
#import "CLBInAppNotificationView.h"

@interface CLBInAppNotificationViewController()

@property CLBInAppNotificationView* inAppNotif;

@end

@implementation CLBInAppNotificationViewController

-(void)dealloc {
    [self.view.layer removeAllAnimations];
}

-(instancetype)initWithMessage:(CLBMessage *)message avatar:(UIImage *)avatarImage conversation:(CLBConversation*)conversation {
    self = [super init];
    if (self) {
        _message = message;
        _conversation = conversation;
        _inAppNotif = [[CLBInAppNotificationView alloc] initWithMessage:self.message avatar:avatarImage target:self action:@selector(onCancel)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];

    self.inAppNotif.frame = CGRectMake(0, -CLBInAppNotificationViewHeight, self.view.bounds.size.width, CLBInAppNotificationViewHeight);
    [self.view addSubview:self.inAppNotif];

    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.inAppNotif addGestureRecognizer:singleFingerTap];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self slideDown];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.inAppNotif.frame = CGRectMake(0, self.inAppNotif.frame.origin.y, self.view.bounds.size.width, CLBInAppNotificationViewHeight);
}

-(void)onCancel {
    [self slideUpWithCompletion:^{
        if([self.delegate respondsToSelector:@selector(notificationViewControllerDidDismissNotification:)]){
            [self.delegate notificationViewControllerDidDismissNotification:self];
        }
    }];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    [self slideUpWithCompletion:^{
        if([self.delegate respondsToSelector:@selector(notificationViewControllerDidSelectNotification:)]){
            [self.delegate notificationViewControllerDidSelectNotification:self];
        }
    }];
}

-(void)slideDown {
    [self.inAppNotif animateAvatarAndLabel];
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseOut
                     animations:^{
                         self.inAppNotif.frame = CGRectMake(0, 0, self.inAppNotif.frame.size.width, self.inAppNotif.frame.size.height);
                     } completion:nil];
}

-(void)slideUpWithCompletion:(void (^)(void))completion {
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.inAppNotif.frame = CGRectMake(0, -self.inAppNotif.frame.size.height, self.inAppNotif.frame.size.width, self.inAppNotif.frame.size.height);
                     } completion:^(BOOL finished){
                         if(completion){
                             completion();
                         }
                     }];
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(self.inAppNotif.frame, point);
}


-(UIStatusBarStyle)preferredStatusBarStyle {
    return [UIApplication sharedApplication].statusBarStyle;
}

@end
