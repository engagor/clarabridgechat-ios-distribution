//
//  CLBRemoteOperation.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBRemoteOperation.h"
#import "CLBRemoteObject.h"
#import "CLBApiClient.h"

@interface CLBRemoteOperation()

@property CLBApiClient* apiClient;
@property id<CLBRemoteObject> object;
@property NSString* method;

@end

@implementation CLBRemoteOperation

- (instancetype)initWithApiClient:(CLBApiClient *)apiClient object:(id<CLBRemoteObject>)object method:(NSString *)method {
    self = [super init];
    if (self) {
        _apiClient = apiClient;
        _object = object;
        _method = method;
    }
    return self;
}

-(void)main {
    NSString* remotePath = [self.object remotePath];
    id parameters = [self.method isEqualToString:@"GET"] ? nil : [self.object serialize];

    if (self.apiClient == nil){
        return;
    }

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    __block NSHTTPURLResponse *response;
    __block NSError *error;
    __block id responseObject;

    [self.apiClient requestWithMethod:self.method url:remotePath parameters:parameters completion:^(NSURLSessionDataTask *task, NSError *err, id obj) {
        response = (NSHTTPURLResponse*)task.response;
        error = err;
        responseObject = obj;

        dispatch_semaphore_signal(semaphore);
    }];

    long retVal = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    if(retVal){
        error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
    }

    if(self.doneBlock){
        self.doneBlock(response, error, responseObject);
    }
}

@end
