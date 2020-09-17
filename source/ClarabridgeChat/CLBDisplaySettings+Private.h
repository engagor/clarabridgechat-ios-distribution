//
//  CLBDisplaySettings+Private.h
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBDisplaySettings.h"

@interface CLBDisplaySettings(Private) < NSCoding, NSCopying >

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;
-(id)serialize;

@end
