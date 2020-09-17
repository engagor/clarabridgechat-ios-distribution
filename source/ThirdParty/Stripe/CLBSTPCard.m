//
//  CLBSTPCard.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/2/12.
//
//

#import "CLBSTPCard.h"
#import "CLBStripeError.h"
#import "CLBSTPCardValidator.h"

@interface CLBSTPCard ()

@property (nonatomic, readwrite) NSString *cardId;
@property (nonatomic, readwrite) NSString *last4;
@property (nonatomic, readwrite) NSString *dynamicLast4;
@property (nonatomic, readwrite) CLBSTPCardBrand brand;
@property (nonatomic, readwrite) CLBSTPCardFundingType funding;
@property (nonatomic, readwrite) NSString *fingerprint;
@property (nonatomic, readwrite) NSString *country;

@end

@implementation CLBSTPCard

@dynamic number, cvc, expMonth, expYear, currency, name, addressLine1, addressLine2, addressCity, addressState, addressZip, addressCountry;

- (instancetype)init {
    self = [super init];
    if (self) {
        _brand = CLBSTPCardBrandUnknown;
        _funding = CLBSTPCardFundingTypeOther;
    }

    return self;
}

- (NSString *)last4 {
    return _last4 ?: [super last4];
}

- (NSString *)type {
    switch (self.brand) {
    case CLBSTPCardBrandAmex:
        return @"American Express";
    case CLBSTPCardBrandDinersClub:
        return @"Diners Club";
    case CLBSTPCardBrandDiscover:
        return @"Discover";
    case CLBSTPCardBrandJCB:
        return @"JCB";
    case CLBSTPCardBrandMasterCard:
        return @"MasterCard";
    case CLBSTPCardBrandVisa:
        return @"Visa";
    default:
        return @"Unknown";
    }
}

- (BOOL)isEqual:(id)other {
    return [self isEqualToCard:other];
}

- (NSUInteger)hash {
    return [self.cardId hash];
}

- (BOOL)isEqualToCard:(CLBSTPCard *)other {
    if (self == other) {
        return YES;
    }

    if (!other || ![other isKindOfClass:self.class]) {
        return NO;
    }
    
    return [self.cardId isEqualToString:other.cardId];
}
@end
