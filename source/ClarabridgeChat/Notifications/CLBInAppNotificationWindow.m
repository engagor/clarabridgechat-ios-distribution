//
//  CLBInAppNotificationWindow.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBInAppNotificationWindow.h"
#import "CLBInAppNotificationViewController.h"
#import "CLBUtility.h"

@implementation CLBInAppNotificationWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

// Ignore touches that are not on the notification
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CLBInAppNotificationViewController* castedVC = (CLBInAppNotificationViewController*)self.rootViewController;
    return [castedVC pointInside:point withEvent:event];
}

@end
