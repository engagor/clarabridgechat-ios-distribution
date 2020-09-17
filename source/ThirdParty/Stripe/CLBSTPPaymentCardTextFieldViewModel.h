//
//  CLBSTPPaymentCardTextFieldViewModel.h
//  Stripe
//
//  Created by Jack Flintermann on 7/21/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "CLBSTPCard.h"
#import "CLBSTPCardValidator.h"

typedef NS_ENUM(NSInteger, CLBSTPCardFieldType) {
    CLBSTPCardFieldTypeNumber,
    CLBSTPCardFieldTypeExpiration,
    CLBSTPCardFieldTypeCVC,
};

@interface CLBSTPPaymentCardTextFieldViewModel : NSObject

@property(nonatomic, readwrite, copy, nullable)NSString *cardNumber;
@property(nonatomic, readwrite, copy, nullable)NSString *rawExpiration;
@property(nonatomic, readonly, nullable)NSString *expirationMonth;
@property(nonatomic, readonly, nullable)NSString *expirationYear;
@property(nonatomic, readwrite, copy, nullable)NSString *cvc;
@property(nonatomic, readonly) CLBSTPCardBrand brand;

- (nonnull NSString *)defaultPlaceholder;
- (nullable NSString *)numberWithoutLastDigits;

- (BOOL)isValid;

- (CLBSTPCardValidationState)validationStateForField:(CLBSTPCardFieldType)fieldType;

+ (nullable UIImage*)brandImageForCardBrand:(CLBSTPCardBrand)brand;
- (nullable UIImage *)brandImage;
- (nullable UIImage *)cvcImage;

@end
