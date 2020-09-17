//
//  CLBRetryConfiguration.h
//  ClarabridgeChat
//
//  Copyright © 2017 Radialpoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLBRetryConfiguration : NSObject

@property NSInteger baseRetryIntervalAggressive;
@property NSInteger baseRetryIntervalRegular;
@property NSInteger maxRetries;
@property NSInteger retryBackoffMultiplier;

-(NSInteger)jitteredWaitIntervalWithBaseInterval:(NSInteger)baseInterval retryCount:(NSInteger)retryCount;

-(void)save;

@end
