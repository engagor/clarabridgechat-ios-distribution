//
//  CLBSTPCardParams.m
//  Stripe
//
//  Created by Jack Flintermann on 10/4/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "CLBSTPCardParams.h"
#import "CLBSTPCardValidator.h"
#import "CLBStripeError.h"

@implementation CLBSTPCardParams

- (NSString *)last4 {
    if (self.number && self.number.length >= 4) {
        return [self.number substringFromIndex:(self.number.length - 4)];
    } else {
        return nil;
    }
}

- (BOOL)validateNumber:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        return [self.class handleValidationErrorForParameter:@"number" error:outError];
    }
    NSString *ioValueString = (NSString *)*ioValue;
    
    if ([CLBSTPCardValidator validationStateForNumber:ioValueString validatingCardBrand:NO] != CLBSTPCardValidationStateValid) {
        return [self.class handleValidationErrorForParameter:@"number" error:outError];
    }
    return YES;
}

- (BOOL)validateCvc:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        return [self.class handleValidationErrorForParameter:@"number" error:outError];
    }
    NSString *ioValueString = (NSString *)*ioValue;
    
    CLBSTPCardBrand brand = [CLBSTPCardValidator brandForNumber:self.number];
    
    if ([CLBSTPCardValidator validationStateForCVC:ioValueString cardBrand:brand] != CLBSTPCardValidationStateValid) {
        return [self.class handleValidationErrorForParameter:@"cvc" error:outError];
    }
    return YES;
}

- (BOOL)validateExpMonth:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        return [self.class handleValidationErrorForParameter:@"expMonth" error:outError];
    }
    NSString *ioValueString = [(NSString *)*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([CLBSTPCardValidator validationStateForExpirationMonth:ioValueString] != CLBSTPCardValidationStateValid) {
        return [self.class handleValidationErrorForParameter:@"expMonth" error:outError];
    }
    return YES;
}

- (BOOL)validateExpYear:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        return [self.class handleValidationErrorForParameter:@"expYear" error:outError];
    }
    NSString *ioValueString = [(NSString *)*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString *monthString = [@(self.expMonth) stringValue];
    if ([CLBSTPCardValidator validationStateForExpirationYear:ioValueString inMonth:monthString] != CLBSTPCardValidationStateValid) {
        return [self.class handleValidationErrorForParameter:@"expYear" error:outError];
    }
    return YES;
}

- (BOOL)validateCardReturningError:(NSError **)outError {
    // Order matters here
    NSString *numberRef = [self number];
    NSString *expMonthRef = [NSString stringWithFormat:@"%lu", (unsigned long)[self expMonth]];
    NSString *expYearRef = [NSString stringWithFormat:@"%lu", (unsigned long)[self expYear]];
    NSString *cvcRef = [self cvc];
    
    // Make sure expMonth, expYear, and number are set.  Validate CVC if it is provided
    return [self validateNumber:&numberRef error:outError] && [self validateExpYear:&expYearRef error:outError] &&
    [self validateExpMonth:&expMonthRef error:outError] && (cvcRef == nil || [self validateCvc:&cvcRef error:outError]);
}

#pragma mark Private Helpers
+ (BOOL)handleValidationErrorForParameter:(NSString *)parameter error:(NSError **)outError {
    if (outError != nil) {
        if ([parameter isEqualToString:@"number"]) {
            *outError = [self createErrorWithMessage:CLBSTPCardErrorInvalidNumberUserMessage
                                           parameter:parameter
                                       cardErrorCode:CLBSTPInvalidNumber
                                     devErrorMessage:@"Card number must be between 10 and 19 digits long and Luhn valid."];
        } else if ([parameter isEqualToString:@"cvc"]) {
            *outError = [self createErrorWithMessage:CLBSTPCardErrorInvalidCVCUserMessage
                                           parameter:parameter
                                       cardErrorCode:CLBSTPInvalidCVC
                                     devErrorMessage:@"Card CVC must be numeric, 3 digits for Visa, Discover, MasterCard, JCB, and Discover cards, and 3 or 4 "
                         @"digits for American Express cards."];
        } else if ([parameter isEqualToString:@"expMonth"]) {
            *outError = [self createErrorWithMessage:CLBSTPCardErrorInvalidExpMonthUserMessage
                                           parameter:parameter
                                       cardErrorCode:CLBSTPInvalidExpMonth
                                     devErrorMessage:@"expMonth must be less than 13"];
        } else if ([parameter isEqualToString:@"expYear"]) {
            *outError = [self createErrorWithMessage:CLBSTPCardErrorInvalidExpYearUserMessage
                                           parameter:parameter
                                       cardErrorCode:CLBSTPInvalidExpYear
                                     devErrorMessage:@"expYear must be this year or a year in the future"];
        } else {
            // This should not be possible since this is a private method so we
            // know exactly how it is called.  We use CLBSTPAPIError for all errors
            // that are unexpected within the bindings as well.
            *outError = [[NSError alloc] initWithDomain:CLBStripeDomain
                                                   code:CLBSTPAPIError
                                               userInfo:@{
                                                          NSLocalizedDescriptionKey: CLBSTPUnexpectedError,
                                                          CLBSTPErrorMessageKey: @"There was an error within the Stripe client library when trying to generate the "
                                                          @"proper validation error. Contact support@stripe.com if you see this."
                                                          }];
        }
    }
    return NO;
}

+ (NSError *)createErrorWithMessage:(NSString *)userMessage
                          parameter:(NSString *)parameter
                      cardErrorCode:(NSString *)cardErrorCode
                    devErrorMessage:(NSString *)devMessage {
    return [[NSError alloc] initWithDomain:CLBStripeDomain
                                      code:CLBSTPCardError
                                  userInfo:@{
                                             NSLocalizedDescriptionKey: userMessage,
                                             CLBSTPErrorParameterKey: parameter,
                                             CLBSTPCardErrorCodeKey: cardErrorCode,
                                             CLBSTPErrorMessageKey: devMessage
                                             }];
}

#pragma mark - CLBSTPFormEncodable

+ (NSString *)rootObjectName {
    return @"card";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             @"number": @"number",
             @"cvc": @"cvc",
             @"name": @"name",
             @"addressLine1": @"address_line1",
             @"addressLine2": @"address_line2",
             @"addressCity": @"address_city",
             @"addressState": @"address_state",
             @"addressZip": @"address_zip",
             @"addressCountry": @"address_country",
             @"expMonth": @"exp_month",
             @"expYear": @"exp_year",
             @"currency": @"currency",
             };
}

@end
