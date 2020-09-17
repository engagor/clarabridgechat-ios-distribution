//
//  CLBJSONSerializer.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBQueryStringSerializer.h"

@interface CLBJSONSerializer : CLBQueryStringSerializer

- (id)responseObjectForResponse:(NSHTTPURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error;

@end
