//
//  StripeError.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/4/12.
//
//

#import "CLBStripeError.h"
#import "CLBSTPFormEncoder.h"

NSString *const CLBStripeDomain = @"com.stripe.lib";
NSString *const CLBSTPCardErrorCodeKey = @"com.stripe.lib:CardErrorCodeKey";
NSString *const CLBSTPErrorMessageKey = @"com.stripe.lib:ErrorMessageKey";
NSString *const CLBSTPErrorParameterKey = @"com.stripe.lib:ErrorParameterKey";
NSString *const CLBSTPInvalidNumber = @"com.stripe.lib:InvalidNumber";
NSString *const CLBSTPInvalidExpMonth = @"com.stripe.lib:InvalidExpiryMonth";
NSString *const CLBSTPInvalidExpYear = @"com.stripe.lib:InvalidExpiryYear";
NSString *const CLBSTPInvalidCVC = @"com.stripe.lib:InvalidCVC";
NSString *const CLBSTPIncorrectNumber = @"com.stripe.lib:IncorrectNumber";
NSString *const CLBSTPExpiredCard = @"com.stripe.lib:ExpiredCard";
NSString *const CLBSTPCardDeclined = @"com.stripe.lib:CardDeclined";
NSString *const CLBSTPProcessingError = @"com.stripe.lib:ProcessingError";
NSString *const CLBSTPIncorrectCVC = @"com.stripe.lib:IncorrectCVC";

@implementation CLBStripeError

+ (NSError *)CLBSTP_errorFromStripeResponse:(NSDictionary *)jsonDictionary {
    NSDictionary *errorDictionary = jsonDictionary[@"error"];
    if (!errorDictionary) {
        return nil;
    }
    NSString *type = errorDictionary[@"type"];
    NSString *devMessage = errorDictionary[@"message"];
    NSString *parameter = errorDictionary[@"param"];
    NSInteger code = 0;
    
    // There should always be a message and type for the error
    if (devMessage == nil || type == nil) {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: CLBSTPUnexpectedError,
                                   CLBSTPErrorMessageKey: @"Could not interpret the error response that was returned from Stripe."
                                   };
        return [[NSError alloc] initWithDomain:CLBStripeDomain code:CLBSTPAPIError userInfo:userInfo];
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[CLBSTPErrorMessageKey] = devMessage;
    
    if (parameter) {
        userInfo[CLBSTPErrorParameterKey] = [CLBSTPFormEncoder stringByReplacingSnakeCaseWithCamelCase:parameter];
    }
    
    if ([type isEqualToString:@"api_error"]) {
        code = CLBSTPAPIError;
        userInfo[NSLocalizedDescriptionKey] = CLBSTPUnexpectedError;
    } else if ([type isEqualToString:@"invalid_request_error"]) {
        code = CLBSTPInvalidRequestError;
        userInfo[NSLocalizedDescriptionKey] = devMessage;
    } else if ([type isEqualToString:@"card_error"]) {
        code = CLBSTPCardError;
        NSDictionary *errorCodes = @{
                                     @"incorrect_number": @{@"code": CLBSTPIncorrectNumber, @"message": CLBSTPCardErrorInvalidNumberUserMessage},
                                     @"invalid_number": @{@"code": CLBSTPInvalidNumber, @"message": CLBSTPCardErrorInvalidNumberUserMessage},
                                     @"invalid_expiry_month": @{@"code": CLBSTPInvalidExpMonth, @"message": CLBSTPCardErrorInvalidExpMonthUserMessage},
                                     @"invalid_expiry_year": @{@"code": CLBSTPInvalidExpYear, @"message": CLBSTPCardErrorInvalidExpYearUserMessage},
                                     @"invalid_cvc": @{@"code": CLBSTPInvalidCVC, @"message": CLBSTPCardErrorInvalidCVCUserMessage},
                                     @"expired_card": @{@"code": CLBSTPExpiredCard, @"message": CLBSTPCardErrorExpiredCardUserMessage},
                                     @"incorrect_cvc": @{@"code": CLBSTPIncorrectCVC, @"message": CLBSTPCardErrorInvalidCVCUserMessage},
                                     @"card_declined": @{@"code": CLBSTPCardDeclined, @"message": CLBSTPCardErrorDeclinedUserMessage},
                                     @"processing_error": @{@"code": CLBSTPProcessingError, @"message": CLBSTPCardErrorProcessingErrorUserMessage},
                                     };
        NSDictionary *codeMapEntry = errorCodes[errorDictionary[@"code"]];
        
        if (codeMapEntry) {
            userInfo[CLBSTPCardErrorCodeKey] = codeMapEntry[@"code"];
            userInfo[NSLocalizedDescriptionKey] = codeMapEntry[@"message"];
        } else {
            userInfo[CLBSTPCardErrorCodeKey] = errorDictionary[@"code"];
            userInfo[NSLocalizedDescriptionKey] = devMessage;
        }
    }
    
    return [[NSError alloc] initWithDomain:CLBStripeDomain code:code userInfo:userInfo];
}

@end
