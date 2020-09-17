//
//  CLBUserSettings.m
//  ClarabridgeChat
//
//  Copyright © 2017 Radialpoint. All rights reserved.
//

#import "CLBUserSettings.h"

@implementation CLBUserSettings

-(instancetype)init {
    self = [super init];

    if (self) {
        _realtime = [[CLBRealtimeSettings alloc] init];
    }

    return self;
}

-(id)serialize {
    return nil;
}

-(void)deserialize:(NSDictionary *)object {
    [self.realtime deserialize:object[@"realtime"]];
    self.profileEnabled = [object[@"profile"][@"enabled"] boolValue];
    self.uploadInterval = [object[@"profile"][@"uploadInterval"] intValue];
    self.typingEnabled = [object[@"typing"][@"enabled"] boolValue];
}

-(NSString *)remotePath {
    return @"";
}

@end
