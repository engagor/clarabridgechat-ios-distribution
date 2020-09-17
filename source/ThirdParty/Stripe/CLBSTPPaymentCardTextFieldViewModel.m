//
//  CLBSTPPaymentCardTextFieldViewModel.m
//  Stripe
//
//  Created by Jack Flintermann on 7/21/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "CLBSTPPaymentCardTextFieldViewModel.h"
#import "CLBSTPCardValidator.h"
#import "ClarabridgeChat+Private.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

@interface NSString(StripeSubstring)
- (NSString *)CLBSTP_safeSubstringToIndex:(NSUInteger)index;
- (NSString *)CLBSTP_safeSubstringFromIndex:(NSUInteger)index;
@end

@implementation NSString(StripeSubstring)

- (NSString *)CLBSTP_safeSubstringToIndex:(NSUInteger)index {
    return [self substringToIndex:MIN(self.length, index)];
}

- (NSString *)CLBSTP_safeSubstringFromIndex:(NSUInteger)index {
    return (index > self.length) ? @"" : [self substringFromIndex:index];
}

@end

@implementation CLBSTPPaymentCardTextFieldViewModel

- (void)setCardNumber:(NSString *)cardNumber {
    NSString *sanitizedNumber = [CLBSTPCardValidator sanitizedNumericStringForString:cardNumber];
    CLBSTPCardBrand brand = [CLBSTPCardValidator brandForNumber:sanitizedNumber];
    NSInteger maxLength = [CLBSTPCardValidator lengthForCardBrand:brand];
    _cardNumber = [sanitizedNumber CLBSTP_safeSubstringToIndex:maxLength];
}

// This might contain slashes.
- (void)setRawExpiration:(NSString *)expiration {
    NSString *sanitizedExpiration = [CLBSTPCardValidator sanitizedNumericStringForString:expiration];
    self.expirationMonth = [sanitizedExpiration CLBSTP_safeSubstringToIndex:2];
    self.expirationYear = [[sanitizedExpiration CLBSTP_safeSubstringFromIndex:2] CLBSTP_safeSubstringToIndex:2];
}

- (NSString *)rawExpiration {
    NSMutableArray *array = [@[] mutableCopy];
    if (self.expirationMonth && ![self.expirationMonth isEqualToString:@""]) {
        [array addObject:self.expirationMonth];
    }
    
    if ([CLBSTPCardValidator validationStateForExpirationMonth:self.expirationMonth] == CLBSTPCardValidationStateValid) {
        [array addObject:self.expirationYear];
    }
    return [array componentsJoinedByString:@"/"];
}

- (void)setExpirationMonth:(NSString *)expirationMonth {
    NSString *sanitizedExpiration = [CLBSTPCardValidator sanitizedNumericStringForString:expirationMonth];
    if (sanitizedExpiration.length == 1 && ![sanitizedExpiration isEqualToString:@"0"] && ![sanitizedExpiration isEqualToString:@"1"]) {
        sanitizedExpiration = [@"0" stringByAppendingString:sanitizedExpiration];
    }
    _expirationMonth = [sanitizedExpiration CLBSTP_safeSubstringToIndex:2];
}

- (void)setExpirationYear:(NSString *)expirationYear {
    _expirationYear = [[CLBSTPCardValidator sanitizedNumericStringForString:expirationYear] CLBSTP_safeSubstringToIndex:2];
}

- (void)setCvc:(NSString *)cvc {
    NSInteger maxLength = [CLBSTPCardValidator maxCVCLengthForCardBrand:self.brand];
    _cvc = [[CLBSTPCardValidator sanitizedNumericStringForString:cvc] CLBSTP_safeSubstringToIndex:maxLength];
}

- (CLBSTPCardBrand)brand {
    return [CLBSTPCardValidator brandForNumber:self.cardNumber];
}

- (CLBSTPCardValidationState)validationStateForField:(CLBSTPCardFieldType)fieldType {
    switch (fieldType) {
        case CLBSTPCardFieldTypeNumber:
            return [CLBSTPCardValidator validationStateForNumber:self.cardNumber validatingCardBrand:YES];
            break;
        case CLBSTPCardFieldTypeExpiration: {
            CLBSTPCardValidationState monthState = [CLBSTPCardValidator validationStateForExpirationMonth:self.expirationMonth];
            CLBSTPCardValidationState yearState = [CLBSTPCardValidator validationStateForExpirationYear:self.expirationYear inMonth:self.expirationMonth];
            if (monthState == CLBSTPCardValidationStateValid && yearState == CLBSTPCardValidationStateValid) {
                return CLBSTPCardValidationStateValid;
            } else if (monthState == CLBSTPCardValidationStateInvalid || yearState == CLBSTPCardValidationStateInvalid) {
                return CLBSTPCardValidationStateInvalid;
            } else {
                return CLBSTPCardValidationStateIncomplete;
            }
            break;
        }
        case CLBSTPCardFieldTypeCVC:
            return [CLBSTPCardValidator validationStateForCVC:self.cvc cardBrand:self.brand];
    }
}

+(UIImage*)brandImageForCardBrand:(CLBSTPCardBrand)brand {
    NSString *imageName;
    BOOL templateSupported = [[UIImage new] respondsToSelector:@selector(imageWithRenderingMode:)];
    switch (brand) {
        case CLBSTPCardBrandAmex:
            imageName = @"stp_card_amex";
            break;
        case CLBSTPCardBrandDinersClub:
            imageName = @"stp_card_diners";
            break;
        case CLBSTPCardBrandDiscover:
            imageName = @"stp_card_discover";
            break;
        case CLBSTPCardBrandJCB:
            imageName = @"stp_card_jcb";
            break;
        case CLBSTPCardBrandMasterCard:
            imageName = @"stp_card_mastercard";
            break;
        case CLBSTPCardBrandUnknown:
            imageName = templateSupported ? @"stp_card_placeholder_template" : @"stp_card_placeholder";
            break;
        case CLBSTPCardBrandVisa:
            imageName = @"stp_card_visa";
    }
    UIImage *image = [self safeImageNamed:imageName];
    if (brand == CLBSTPCardBrandUnknown && templateSupported) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return image;
}

- (UIImage *)brandImage {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    return [[self class] brandImageForCardBrand:self.brand];
}

- (UIImage *)cvcImage {
    NSString *imageName = self.brand == CLBSTPCardBrandAmex ? @"stp_card_cvc_amex" : @"stp_card_cvc";
    return [self.class safeImageNamed:imageName];
}

+ (UIImage *)safeImageNamed:(NSString *)imageName {
    return [ClarabridgeChat getImageFromResourceBundle:imageName];
}

- (BOOL)isValid {
    return ([self validationStateForField:CLBSTPCardFieldTypeNumber] == CLBSTPCardValidationStateValid &&
            [self validationStateForField:CLBSTPCardFieldTypeExpiration] == CLBSTPCardValidationStateValid &&
            [self validationStateForField:CLBSTPCardFieldTypeCVC] == CLBSTPCardValidationStateValid);
}

- (NSString *)defaultPlaceholder {
    return @"1234567812345678";
}

- (NSString *)numberWithoutLastDigits {
    NSUInteger length = [CLBSTPCardValidator fragmentLengthForCardBrand:[CLBSTPCardValidator brandForNumber:self.cardNumber]];
    NSUInteger toIndex = self.cardNumber.length - length;
    
    return (toIndex < self.cardNumber.length) ?
        [self.cardNumber substringToIndex:toIndex] :
        [self.defaultPlaceholder CLBSTP_safeSubstringToIndex:[self defaultPlaceholder].length - length];

}

@end
