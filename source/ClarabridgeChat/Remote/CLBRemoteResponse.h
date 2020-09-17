//
//  CLBRemoteResponse.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLBRemoteResponse : NSObject

-(instancetype)initWithHttpResponse:(NSHTTPURLResponse*)response error:(NSError*)error;

-(void)deserialize:(NSDictionary*)dict;

@property NSHTTPURLResponse* httpResponse;
@property NSError* error;
@property NSString* clbErrorCode;
@property(readonly) NSDictionary* headers;
@property(readonly) NSInteger statusCode;
@property id responseObject;

@end
