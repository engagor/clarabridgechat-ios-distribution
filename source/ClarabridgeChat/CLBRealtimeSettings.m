//
//  CLBRealtimeSettings.m
//  ClarabridgeChat
//
//  Copyright © 2017 Radialpoint. All rights reserved.
//

#import "CLBRealtimeSettings.h"

@implementation CLBRealtimeSettings

-(void)deserialize:(NSDictionary *)dictionary {
    self.enabled = [dictionary[@"enabled"] boolValue];
    self.baseUrl = dictionary[@"baseUrl"];
    self.retryInterval = [dictionary[@"retryInterval"] intValue];
    self.maxConnectionAttempts = [dictionary[@"maxConnectionAttempts"] intValue];
    self.connectionDelay = [dictionary[@"connectionDelay"] intValue];
}

@end
