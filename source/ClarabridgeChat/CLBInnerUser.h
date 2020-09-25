//
//  CLBInnerUser.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBUser.h"

@interface CLBInnerUser : NSObject

@property NSString* firstName;
@property NSString* lastName;
@property NSString* email;
@property NSString* signedUpAt;

@property NSDictionary* metadata;
-(void)addMetadata:(NSDictionary*)metadata;

-(void)deserialize:(NSDictionary*)dict;
-(NSDictionary*)serialize;

-(void)clearMetadata;

@end
