//
//  CLBNavigationBar.m
//  ClarabridgeChat
//
//  Copyright © 2017 Radialpoint. All rights reserved.
//

#import "CLBNavigationBar.h"
#import "CLBUtility.h"

@implementation CLBNavigationBar

- (void)layoutSubviews {
    [super layoutSubviews];

    if(CLBIsIOS11OrLater()) {
        for (UIView *subview in self.subviews) {
            if ([NSStringFromClass([subview class]) containsString:@"BarBackground"]) {
                CGRect safeBounds = CLBSafeBoundsForView(self.superview);
                CGRect subViewFrame = subview.frame;
                subViewFrame.origin.y = -safeBounds.origin.y;
                subViewFrame.size.height = self.frame.size.height + safeBounds.origin.y;
                [subview setFrame: subViewFrame];
            }
        }
    }
}

@end
