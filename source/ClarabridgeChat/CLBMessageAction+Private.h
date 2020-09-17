//
//  CLBMessageAction+Private.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <ClarabridgeChat/CLBMessageAction.h>

@interface CLBMessageAction(Private) < NSCoding, NSCopying >

+(NSArray*)deserializeActions:(NSArray*)actionObjects;

-(instancetype)initWithDictionary:(NSDictionary*)dictionary;
-(id)serialize;
-(BOOL)isEnabled;
-(BOOL)isProcessing;

@property NSString* actionId;
@property NSString* state;
@property NSString* uiState;

extern NSString* const CLBMessageActionUIStateProcessing;

@end
