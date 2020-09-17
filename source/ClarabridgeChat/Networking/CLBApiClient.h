//
//  CLBApiClient.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLBAPIClientProtocol.h"
@class CLBQueryStringSerializer;
@class CLBJSONSerializer;

extern NSString *const CLBErrorStatusCode;

typedef NSDictionary *(^CLBGetRequestHeadersBlock)(void);

@interface CLBApiClient : NSObject <CLBAPIClientProtocol>

- (instancetype)initWithBaseURL:(NSString *)url;

@property NSURL *baseURL;
@property CLBQueryStringSerializer *requestSerializer;
@property CLBJSONSerializer *responseSerializer;
@property CLBGetRequestHeadersBlock headersBlock;

@end
