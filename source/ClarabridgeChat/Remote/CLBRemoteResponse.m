//
//  CLBRemoteResponse.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBRemoteResponse.h"

@implementation CLBRemoteResponse

-(instancetype)initWithHttpResponse:(NSHTTPURLResponse *)response error:(NSError *)error {
    self = [super init];
    if(self){
        _httpResponse = response;
        _error = error;
    }
    return self;
}

-(void)deserialize:(NSDictionary *)dict {
    self.clbErrorCode = dict[@"error"][@"code"];
}

-(NSDictionary*)headers {
    return [self.httpResponse allHeaderFields];
}

-(NSInteger)statusCode {
    return self.httpResponse.statusCode;
}

@end
