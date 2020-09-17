//
//  StripeError.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/4/12.
//
//

#import <Foundation/Foundation.h>

/**
 *  All Stripe iOS errors will be under this domain.
 */
FOUNDATION_EXPORT NSString * __nonnull const CLBStripeDomain;

typedef NS_ENUM(NSInteger, CLBSTPErrorCode) {
    CLBSTPConnectionError = 40,     // Trouble connecting to Stripe.
    CLBSTPInvalidRequestError = 50, // Your request had invalid parameters.
    CLBSTPAPIError = 60,            // General-purpose API error (should be rare).
    CLBSTPCardError = 70,           // Something was wrong with the given card (most common).
    CLBSTPCheckoutError = 80,       // Stripe Checkout encountered an error.
};

#pragma mark userInfo keys

// A developer-friendly error message that explains what went wrong. You probably
// shouldn't show this to your users, but might want to use it yourself.
FOUNDATION_EXPORT NSString * __nonnull const CLBSTPErrorMessageKey;

// What went wrong with your CLBSTPCard (e.g., CLBSTPInvalidCVC. See below for full list).
FOUNDATION_EXPORT NSString * __nonnull const CLBSTPCardErrorCodeKey;

// Which parameter on the CLBSTPCard had an error (e.g., "cvc"). Useful for marking up the
// right UI element.
FOUNDATION_EXPORT NSString * __nonnull const CLBSTPErrorParameterKey;

#pragma mark CLBSTPCardErrorCodeKeys

// (Usually determined locally:)
FOUNDATION_EXPORT NSString * __nonnull const CLBSTPInvalidNumber;
FOUNDATION_EXPORT NSString * __nonnull const CLBSTPInvalidExpMonth;
FOUNDATION_EXPORT NSString * __nonnull const CLBSTPInvalidExpYear;
FOUNDATION_EXPORT NSString * __nonnull const CLBSTPInvalidCVC;

// (Usually sent from the server:)
FOUNDATION_EXPORT NSString * __nonnull const CLBSTPIncorrectNumber;
FOUNDATION_EXPORT NSString * __nonnull const CLBSTPExpiredCard;
FOUNDATION_EXPORT NSString * __nonnull const CLBSTPCardDeclined;
FOUNDATION_EXPORT NSString * __nonnull const CLBSTPProcessingError;
FOUNDATION_EXPORT NSString * __nonnull const CLBSTPIncorrectCVC;

#pragma mark Strings

#define CLBSTPCardErrorInvalidNumberUserMessage NSLocalizedString(@"Your card's number is invalid", @"Error when the card number is not valid")
#define CLBSTPCardErrorInvalidCVCUserMessage NSLocalizedString(@"Your card's security code is invalid", @"Error when the card's CVC is not valid")
#define CLBSTPCardErrorInvalidExpMonthUserMessage                                                                                                                 \
    NSLocalizedString(@"Your card's expiration month is invalid", @"Error when the card's expiration month is not valid")
#define CLBSTPCardErrorInvalidExpYearUserMessage                                                                                                                  \
    NSLocalizedString(@"Your card's expiration year is invalid", @"Error when the card's expiration year is not valid")
#define CLBSTPCardErrorExpiredCardUserMessage NSLocalizedString(@"Your card has expired", @"Error when the card has already expired")
#define CLBSTPCardErrorDeclinedUserMessage NSLocalizedString(@"Your card was declined", @"Error when the card was declined by the credit card networks")
#define CLBSTPUnexpectedError                                                                                                                                     \
    NSLocalizedString(@"There was an unexpected error -- try again in a few seconds", @"Unexpected error, such as a 500 from Stripe or a JSON parse error")
#define CLBSTPCardErrorProcessingErrorUserMessage                                                                                                                 \
    NSLocalizedString(@"There was an error processing your card -- try again in a few seconds", @"Error when there is a problem processing the credit card")

@interface CLBStripeError : NSObject

+ (nullable NSError *)CLBSTP_errorFromStripeResponse:(nullable NSDictionary *)jsonDictionary;

@end
