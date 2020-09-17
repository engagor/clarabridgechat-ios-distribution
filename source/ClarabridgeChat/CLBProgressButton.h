//
//  CLBBuyButton.h
//  ClarabridgeChat
//
//  Copyright © 2015 Radialpoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLBProgressButton : UIButton

-(instancetype)initWithFrame:(CGRect)frame activityIndicatorStyle:(UIActivityIndicatorViewStyle)style;

-(void)setProcessing:(BOOL)processing;
-(void)setCompleted;
-(void)resetToWidth:(CGFloat)width;

@property(nonatomic) BOOL shown;
@property(nonatomic) BOOL shrinkOnProcessing;

@end
