//
//  CLBRoundedRectView.h
//  ClarabridgeChat
//
//  Copyright © 2016 Radialpoint. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSInteger, CLBCorners) {
    CLBCornerNone = 1 << 0,
    CLBCornerTopRight = 1 << 1,
    CLBCornerTopLeft = 1 << 2,
    CLBCornerBottomLeft = 1 << 3,
    CLBCornerBottomRight = 1 << 4
};

@interface CLBRoundedRectView : UIView

@property(nonatomic) CLBCorners flatCorners;

@end
