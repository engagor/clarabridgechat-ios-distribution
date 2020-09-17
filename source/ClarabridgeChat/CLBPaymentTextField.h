//
//  CLBPaymentTextField.h
//  ClarabridgeChat
//
//  Copyright © 2016 Radialpoint. All rights reserved.
//

#import "CLBSTPPaymentCardTextField.h"

@interface CLBPaymentTextField : CLBSTPPaymentCardTextField

-(UIImage*)brandImageFromString:(NSString*)string;

@property(nonatomic) UIImage* brandImageOverride;

@end
