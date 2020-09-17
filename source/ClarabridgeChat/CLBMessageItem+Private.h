//
//  CLBMessageItem+Private.h
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBMessageItem.h"

@interface CLBMessageItem(Private) < NSCoding, NSCopying >

-(instancetype)initWithDictionary:(NSDictionary*)dictionary;
-(id)serialize;

@end
