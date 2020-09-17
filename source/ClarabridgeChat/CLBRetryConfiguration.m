//
//  CLBRetryConfiguration.m
//  ClarabridgeChat
//
//  Copyright © 2017 Radialpoint. All rights reserved.
//

#import "CLBRetryConfiguration.h"
#import "CLBPersistence.h"

static int const kBaseRetryIntervalAggressiveStrategy = 15;
static int const kBaseRetryIntervalRegularStrategy = 60;
static int const kMaxNumberOfRetries = 5;
static int const kRetryBackoffMultiplier = 2;

static NSString * const CLBBaseRetryIntervalAggressive = @"CLBBaseRetryIntervalAggressive";
static NSString * const CLBBaseRetryIntervalRegular = @"CLBBaseRetryIntervalRegular";
static NSString * const CLBMaxRetries = @"CLBMaxRetries";
static NSString * const CLBBackoffMultiplier = @"CLBBackoffMultiplier";

@interface CLBRetryConfiguration()

@property (copy, nonatomic) NSString *appId;

@end

@implementation CLBRetryConfiguration

-(instancetype)init {
    self = [super init];

    if (self) {
        [self loadValues];
    }

    return self;
}

-(void)loadValues {
    [[CLBPersistence sharedPersistence] ensureProtectedDataAvailable:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        self.baseRetryIntervalAggressive = [defaults integerForKey:[self defaultsKeyForKey:CLBBaseRetryIntervalAggressive]];
        self.baseRetryIntervalRegular = [defaults integerForKey:[self defaultsKeyForKey:CLBBaseRetryIntervalRegular]];
        self.maxRetries = [defaults integerForKey:[self defaultsKeyForKey:CLBMaxRetries]];
        self.retryBackoffMultiplier = [defaults integerForKey:[self defaultsKeyForKey:CLBBackoffMultiplier]];
    }];

    self.baseRetryIntervalAggressive = self.baseRetryIntervalAggressive ?: kBaseRetryIntervalAggressiveStrategy;
    self.baseRetryIntervalRegular = self.baseRetryIntervalRegular ?: kBaseRetryIntervalRegularStrategy;
    self.maxRetries = self.maxRetries ?: kMaxNumberOfRetries;
    self.retryBackoffMultiplier = self.retryBackoffMultiplier ?: kRetryBackoffMultiplier;
}

-(void)save {
    [[CLBPersistence sharedPersistence] ensureProtectedDataAvailable:^{
        [[NSUserDefaults standardUserDefaults] setInteger:self.baseRetryIntervalAggressive forKey:[self defaultsKeyForKey:CLBBaseRetryIntervalAggressive]];
        [[NSUserDefaults standardUserDefaults] setInteger:self.baseRetryIntervalRegular forKey:[self defaultsKeyForKey:CLBBaseRetryIntervalRegular]];
        [[NSUserDefaults standardUserDefaults] setInteger:self.maxRetries forKey:[self defaultsKeyForKey:CLBMaxRetries]];
        [[NSUserDefaults standardUserDefaults] setInteger:self.retryBackoffMultiplier forKey:[self defaultsKeyForKey:CLBBackoffMultiplier]];
    }];
}

-(NSString *)defaultsKeyForKey:(NSString *)key {
    return [NSString stringWithFormat:@"%@", key];
}

-(NSInteger)jitteredWaitIntervalWithBaseInterval:(NSInteger)baseInterval retryCount:(NSInteger)retryCount {
    int waitInterval = baseInterval * pow(self.retryBackoffMultiplier, retryCount);

    return ((2 * waitInterval) / 3) + arc4random_uniform(waitInterval / 3);
}

@end
