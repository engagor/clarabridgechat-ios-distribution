//
//  CLBRemoteObjectSynchronizer.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBRemoteObjectSynchronizer.h"
#import "CLBRemoteObject.h"
#import "CLBRemoteOperation.h"
#import "CLBRemoteResponse.h"
#import "ClarabridgeChat+Private.h"
#import "CLBApiClient.h"
#import "CLBAPIClientProtocol.h"

@interface CLBRemoteObjectSynchronizer()

@property NSOperationQueue* operationQueue;

@end

@implementation CLBRemoteObjectSynchronizer

-(instancetype)initWithApiClient:(CLBApiClient *)apiClient {
    self = [super init];
    if (self) {
        _apiClient = apiClient;
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

-(void)dealloc {
    [self.operationQueue cancelAllOperations];
}

-(void)fetch:(id<CLBRemoteObject>)object completion:(void (^)(CLBRemoteResponse* response))completion {
    NSString* method = @"GET";
    if([object respondsToSelector:@selector(fetchMethod)]){
        method = [object fetchMethod];
    }
    [self queueRequest:method object:object completion:completion];
}

-(void)synchronize:(id<CLBRemoteObject>)object completion:(void (^)(CLBRemoteResponse* response))completion {
    NSString* method = @"POST";
    if([object respondsToSelector:@selector(synchronizeMethod)]){
        method = [object synchronizeMethod];
    }
    [self queueRequest:method object:object completion:completion];
}

-(void)queueRequest:(NSString*)method object:(id<CLBRemoteObject>)object completion:(void (^)(CLBRemoteResponse* response))completion {
    CLBRemoteOperation* op = [[CLBRemoteOperation alloc] initWithApiClient:self.apiClient object:object method:method];

    // Cannot use the completionBlock property of NSOperation, since it does not execute before the next operation starts
    op.doneBlock = ^(NSHTTPURLResponse *httpResponse, NSError *error, id responseObject) {
        CLBRemoteResponse* response = [[CLBRemoteResponse alloc] initWithHttpResponse:httpResponse error:error];
        response.responseObject = responseObject;

        if(error){
            CLBDebug(@"%@ failed for object : %@, %@", method, object, error);

            if([responseObject isKindOfClass:[NSDictionary class]] && [responseObject count] > 0){
                [response deserialize:responseObject];
            }
        }else{
            CLBDebug(@"%@ succeeded for object : %@\nResponse: %@", method, object, responseObject);

            if([responseObject isKindOfClass:[NSDictionary class]] && [responseObject count] > 0){
                [object deserialize:responseObject];
            }
        }

        if(completion){
            completion(response);
        }
    };

    [self.operationQueue addOperation:op];
}

@end
