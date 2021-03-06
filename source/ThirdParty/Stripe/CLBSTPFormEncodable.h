//
//  CLBSTPFormEncodable.h
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CLBSTPFormEncodable <NSObject>

+ (NSString *)rootObjectName;
+ (NSDictionary *)propertyNamesToFormFieldNamesMapping;

@end
