//
//  CLBPaymentTextField.m
//  ClarabridgeChat
//
//  Copyright © 2016 Radialpoint. All rights reserved.
//

#import "CLBPaymentTextField.h"
#import "CLBSTPPaymentCardTextFieldViewModel.h"

@implementation CLBPaymentTextField

-(UIImage*)brandImageFromString:(NSString *)string {
    string = [string lowercaseString];
    CLBSTPCardBrand brand;

    if([string isEqualToString:@"visa"]){
        brand = CLBSTPCardBrandVisa;
    }else if([string isEqualToString:@"american express"]){
        brand = CLBSTPCardBrandAmex;
    }else if([string isEqualToString:@"mastercard"]){
        brand = CLBSTPCardBrandMasterCard;
    }else if([string isEqualToString:@"discover"]){
        brand = CLBSTPCardBrandDiscover;
    }else if([string isEqualToString:@"jcb"]){
        brand = CLBSTPCardBrandJCB;
    }else if([string isEqualToString:@"diners club"]){
        brand = CLBSTPCardBrandDinersClub;
    }else{
        brand = CLBSTPCardBrandUnknown;
    }

    return [CLBSTPPaymentCardTextFieldViewModel brandImageForCardBrand:brand];
}

-(UIImage*)brandImageForCardBrand:(CLBSTPCardBrand)cardBrand {
    if(self.brandImageOverride){
        return self.brandImageOverride;
    }else{
        return [super brandImageForCardBrand:cardBrand];
    }
}

-(void)setBrandImageOverride:(UIImage *)brandImageOverride {
    _brandImageOverride = brandImageOverride;

    // Force redraw of brand image
    [self clear];
}

@end
