//
//  CLBSTPFormEncoder.h
//  Stripe
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLBSTPCardParams, CLBSTPBankAccountParams;
@protocol CLBSTPFormEncodable;

@interface CLBSTPFormEncoder : NSObject

+ (nonnull NSData *)formEncodedDataForObject:(nonnull NSObject<CLBSTPFormEncodable> *)object;

+ (nonnull NSString *)stringByURLEncoding:(nonnull NSString *)string;

+ (nonnull NSString *)stringByReplacingSnakeCaseWithCamelCase:(nonnull NSString *)input;

@end
