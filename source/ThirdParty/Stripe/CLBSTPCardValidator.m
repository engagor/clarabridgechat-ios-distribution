//
//  CLBSTPCardValidator.m
//  Stripe
//
//  Created by Jack Flintermann on 7/15/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "CLBSTPCardValidator.h"

@implementation CLBSTPCardValidator

+ (NSString *)sanitizedNumericStringForString:(NSString *)string {
    NSCharacterSet *set = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSArray *components = [string componentsSeparatedByCharactersInSet:set];
    return [components componentsJoinedByString:@""] ?: @"";
}

+ (NSString *)stringByRemovingSpacesFromString:(NSString *)string {
    NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
    NSArray *components = [string componentsSeparatedByCharactersInSet:set];
    return [components componentsJoinedByString:@""];
}

+ (BOOL)stringIsNumeric:(NSString *)string {
    return [[self sanitizedNumericStringForString:string] isEqualToString:string];
}

+ (CLBSTPCardValidationState)validationStateForExpirationMonth:(NSString *)expirationMonth {

    NSString *sanitizedExpiration = [self stringByRemovingSpacesFromString:expirationMonth];
    
    if (![self stringIsNumeric:sanitizedExpiration]) {
        return CLBSTPCardValidationStateInvalid;
    }
    
    switch (sanitizedExpiration.length) {
        case 0:
            return CLBSTPCardValidationStateIncomplete;
        case 1:
            return ([sanitizedExpiration isEqualToString:@"0"] || [sanitizedExpiration isEqualToString:@"1"]) ? CLBSTPCardValidationStateIncomplete : CLBSTPCardValidationStateValid;
        case 2:
            return (0 < sanitizedExpiration.integerValue && sanitizedExpiration.integerValue <= 12) ? CLBSTPCardValidationStateValid : CLBSTPCardValidationStateInvalid;
        default:
            return CLBSTPCardValidationStateInvalid;
    }
}

+ (CLBSTPCardValidationState)validationStateForExpirationYear:(NSString *)expirationYear inMonth:(NSString *)expirationMonth inCurrentYear:(NSInteger)currentYear currentMonth:(NSInteger)currentMonth {
    
    NSInteger moddedYear = currentYear % 100;
    
    if (![self stringIsNumeric:expirationMonth] || ![self stringIsNumeric:expirationYear]) {
        return CLBSTPCardValidationStateInvalid;
    }
    
    NSString *sanitizedMonth = [self sanitizedNumericStringForString:expirationMonth];
    NSString *sanitizedYear = [self sanitizedNumericStringForString:expirationYear];
    
    switch (sanitizedYear.length) {
        case 0:
        case 1:
            return CLBSTPCardValidationStateIncomplete;
        case 2: {
            if (sanitizedYear.integerValue == moddedYear) {
                return sanitizedMonth.integerValue >= currentMonth ? CLBSTPCardValidationStateValid : CLBSTPCardValidationStateInvalid;
            } else {
                return sanitizedYear.integerValue > moddedYear ? CLBSTPCardValidationStateValid : CLBSTPCardValidationStateInvalid;
            }
        }
        default:
            return CLBSTPCardValidationStateInvalid;
    }
}


+ (CLBSTPCardValidationState)validationStateForExpirationYear:(NSString *)expirationYear
                                                   inMonth:(NSString *)expirationMonth {
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:[NSDate date]];
    NSInteger currentYear = dateComponents.year % 100;
    NSInteger currentMonth = dateComponents.month;
    
    return [self validationStateForExpirationYear:expirationYear inMonth:expirationMonth inCurrentYear:currentYear currentMonth:currentMonth];
}


+ (CLBSTPCardValidationState)validationStateForCVC:(NSString *)cvc cardBrand:(CLBSTPCardBrand)brand {
    
    if (![self stringIsNumeric:cvc]) {
        return CLBSTPCardValidationStateInvalid;
    }
    
    NSString *sanitizedCvc = [self sanitizedNumericStringForString:cvc];
    
    NSUInteger minLength = [self minCVCLength];
    NSUInteger maxLength = [self maxCVCLengthForCardBrand:brand];
    if (sanitizedCvc.length < minLength) {
        return CLBSTPCardValidationStateIncomplete;
    }
    else if (sanitizedCvc.length > maxLength) {
        return CLBSTPCardValidationStateInvalid;
    }
    else {
        return CLBSTPCardValidationStateValid;
    }
}

+ (CLBSTPCardValidationState)validationStateForNumber:(nonnull NSString *)cardNumber
                               validatingCardBrand:(BOOL)validatingCardBrand {
    
    NSString *sanitizedNumber = [self stringByRemovingSpacesFromString:cardNumber];
    if (![self stringIsNumeric:sanitizedNumber]) {
        return CLBSTPCardValidationStateInvalid;
    }
    
    NSArray *brands = [self possibleBrandsForNumber:sanitizedNumber];
    if (brands.count == 0 && validatingCardBrand) {
        return CLBSTPCardValidationStateInvalid;
    } else if (brands.count >= 2) {
        return CLBSTPCardValidationStateIncomplete;
    } else {
        CLBSTPCardBrand brand = (CLBSTPCardBrand)[brands.firstObject integerValue];
        NSInteger desiredLength = [self lengthForCardBrand:brand];
        if ((NSInteger)sanitizedNumber.length > desiredLength) {
            return CLBSTPCardValidationStateInvalid;
        } else if ((NSInteger)sanitizedNumber.length == desiredLength) {
            return [self stringIsValidLuhn:sanitizedNumber] ? CLBSTPCardValidationStateValid : CLBSTPCardValidationStateInvalid;
        } else {
            return CLBSTPCardValidationStateIncomplete;
        }
    }
}

+ (NSUInteger)minCVCLength {
    return 3;
}

+ (NSUInteger)maxCVCLengthForCardBrand:(CLBSTPCardBrand)brand {
    switch (brand) {
        case CLBSTPCardBrandAmex:
        case CLBSTPCardBrandUnknown:
            return 4;
        default:
            return 3;
    }
}

+ (CLBSTPCardBrand)brandForNumber:(NSString *)cardNumber {
    NSString *sanitizedNumber = [self sanitizedNumericStringForString:cardNumber];
    NSArray *brands = [self possibleBrandsForNumber:sanitizedNumber];
    if (brands.count == 1) {
        return (CLBSTPCardBrand)[brands.firstObject integerValue];
    }
    return CLBSTPCardBrandUnknown;
}

+ (NSArray *)possibleBrandsForNumber:(NSString *)cardNumber {
    NSMutableArray *possibleBrands = [@[] mutableCopy];
    for (NSNumber *brandNumber in [self allValidBrands]) {
        CLBSTPCardBrand brand = (CLBSTPCardBrand)brandNumber.integerValue;
        if ([self prefixMatches:brand digits:cardNumber]) {
            [possibleBrands addObject:@(brand)];
        }
    }
    return [possibleBrands copy];
}

+ (NSArray *)allValidBrands {
    return @[
             @(CLBSTPCardBrandAmex),
             @(CLBSTPCardBrandDinersClub),
             @(CLBSTPCardBrandDiscover),
             @(CLBSTPCardBrandJCB),
             @(CLBSTPCardBrandMasterCard),
             @(CLBSTPCardBrandVisa),
         ];
}

+ (NSInteger)lengthForCardBrand:(CLBSTPCardBrand)brand {
    switch (brand) {
        case CLBSTPCardBrandAmex:
            return 15;
        case CLBSTPCardBrandDinersClub:
            return 14;
        default:
            return 16;
    }
}

+ (NSInteger)fragmentLengthForCardBrand:(CLBSTPCardBrand)brand {
    switch (brand) {
        case CLBSTPCardBrandAmex:
            return 5;
        case CLBSTPCardBrandDinersClub:
            return 2;
        default:
            return 4;
    }
}

+ (BOOL)prefixMatches:(CLBSTPCardBrand)brand digits:(NSString *)digits {
    if (digits.length == 0) {
        return YES;
    }
    NSArray *digitPrefixes = [self validBeginningDigits:brand];
    for (NSString *digitPrefix in digitPrefixes) {
        if ((digitPrefix.length >= digits.length && [digitPrefix hasPrefix:digits]) ||
            (digits.length >= digitPrefix.length && [digits hasPrefix:digitPrefix])) {
            return YES;
        }
    }
    return NO;
}

+ (NSArray *)validBeginningDigits:(CLBSTPCardBrand)brand {
    switch (brand) {
        case CLBSTPCardBrandAmex:
            return @[@"34", @"37"];
        case CLBSTPCardBrandDinersClub:
            return @[@"30", @"36", @"38", @"39"];
        case CLBSTPCardBrandDiscover:
            return @[@"6011", @"622", @"64", @"65"];
        case CLBSTPCardBrandJCB:
            return @[@"35"];
        case CLBSTPCardBrandMasterCard:
            return @[@"50", @"51", @"52", @"53", @"54", @"55", @"56", @"57", @"58", @"59"];
        case CLBSTPCardBrandVisa:
            return @[@"40", @"41", @"42", @"43", @"44", @"45", @"46", @"47", @"48", @"49"];
        case CLBSTPCardBrandUnknown:
            return @[];
    }
}

+ (BOOL)stringIsValidLuhn:(NSString *)number {
    BOOL odd = true;
    int sum = 0;
    NSMutableArray *digits = [NSMutableArray arrayWithCapacity:number.length];
    
    for (int i = 0; i < (NSInteger)number.length; i++) {
        [digits addObject:[number substringWithRange:NSMakeRange(i, 1)]];
    }
    
    for (NSString *digitStr in [digits reverseObjectEnumerator]) {
        int digit = [digitStr intValue];
        if ((odd = !odd)) digit *= 2;
        if (digit > 9) digit -= 9;
        sum += digit;
    }
    
    return sum % 10 == 0;
}



@end
