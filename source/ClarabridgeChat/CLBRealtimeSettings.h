//
//  CLBRealtimeSettings.h
//  ClarabridgeChat
//
//  Copyright © 2017 Radialpoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLBRealtimeSettings : NSObject

@property BOOL enabled;
@property (copy, nonatomic) NSString *baseUrl;
@property NSInteger retryInterval;
@property NSInteger maxConnectionAttempts;
@property NSInteger connectionDelay;

-(void)deserialize:(NSDictionary *)dictionary;

@end
