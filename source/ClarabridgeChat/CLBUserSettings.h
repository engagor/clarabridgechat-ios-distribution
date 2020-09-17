//
//  CLBUserSettings.h
//  ClarabridgeChat
//
//  Copyright © 2017 Radialpoint. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBRealtimeSettings.h"
#import "CLBRemoteObject.h"

@interface CLBUserSettings : NSObject <CLBRemoteObject>

@property (strong, nonatomic) CLBRealtimeSettings *realtime;
@property BOOL profileEnabled;
@property NSInteger uploadInterval;
@property BOOL typingEnabled;

@end
