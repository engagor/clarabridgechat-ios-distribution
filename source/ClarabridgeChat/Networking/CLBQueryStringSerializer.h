//
//  CLBQueryStringSerializer.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLBQueryStringSerializer : NSObject

-(void)addQueryStringToRequest:(NSMutableURLRequest*)request withParameters:(id)parameters;

- (NSData*)serializeRequest:(NSMutableURLRequest *)request
             withParameters:(id)parameters
                      error:(NSError * __autoreleasing *)error;

-(NSData*)serializeRequest:(NSMutableURLRequest *)request
                 withImage:(UIImage*)image
                   fileUrl:(NSURL *)fileUrl
                parameters:(NSDictionary*)parameters
                     error:(NSError *__autoreleasing *)error;

@end
