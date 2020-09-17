//
//  CLBClarabridgeChatApiClient.m
//  ClarabridgeChat
//
//  Copyright © 2019 Smooch Technologies. All rights reserved.
//

#import "CLBClarabridgeChatApiClient.h"
#import "CLBUserLifecycleManager.h"
#import "CLBSettings+Private.h"
#import "ClarabridgeChat.h"

static int CLB_MAX_RETRY_ATTEMPTS = 5;

@interface CLBClarabridgeChatApiClient()

@property(weak, nullable) id<CLBAuthenticationDelegate> delegate;
@property CLBAuthenticationCompletionBlock completionBlock;

@end

@implementation CLBClarabridgeChatApiClient

-(instancetype)initWithBaseURL:(NSString *)url authenticationDelegate:(id<CLBAuthenticationDelegate>)authenticationDelegate completion:(CLBAuthenticationCompletionBlock)callback {
    self = [super initWithBaseURL:url];
    
    if (self) {
        _delegate = authenticationDelegate;
        _completionBlock = callback;
    }
    
    return self;
}

-(void)onRequestComplete:(id)response
                   error:(NSError *)error
                    task:(NSURLSessionDataTask *)task
              retryCount:(int)retryCount
              completion:(CLBApiClientCompletionBlock)completionBlock
              retryBlock:(void(^)(void))retryBlock {
    
    if (error && [response isKindOfClass:[NSDictionary class]] && [response[@"error"][@"code"] isEqualToString:@"invalid_auth"]
        && self.delegate && [self.delegate respondsToSelector:@selector(onInvalidToken:handler:)] && retryCount < CLB_MAX_RETRY_ATTEMPTS) {
        NSError *error = [NSError errorWithDomain:CLBErrorDomainIdentifier code:401 userInfo:@{CLBErrorCodeIdentifier: response[@"error"][@"code"], CLBStatusCodeIdentifier: @401}];
        [self.delegate onInvalidToken:error handler:^(NSString *jwt) {
            if (self.completionBlock) {
                self.completionBlock(jwt);
            }
            
            retryBlock();
        }];
    } else if (completionBlock) {
        completionBlock(task, error, response);
    }
}

-(NSURLSessionDataTask*)uploadImage:(UIImage *)image
                                url:(NSString *)urlString
                         parameters:(NSDictionary*)body
                           progress:(CLBApiClientUploadProgressBlock)progress
                         completion:(CLBApiClientCompletionBlock)completion
                        retryCount:(int)retryCount {
    __weak typeof(self) weakSelf = self;
    
    return [super uploadImage:image url:urlString parameters:body progress:progress completion:^(NSURLSessionDataTask *task, NSError *error, id response) {
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf onRequestComplete:response error:error task:task retryCount:retryCount completion:completion retryBlock:^{
            [strongSelf uploadImage:image url:urlString parameters:body progress:progress completion:completion retryCount:retryCount + 1];
        }];
    }];
}

-(NSURLSessionDataTask*)uploadImage:(UIImage *)image
                                url:(NSString *)urlString
                         parameters:(NSDictionary*)body
                           progress:(CLBApiClientUploadProgressBlock)progress
                         completion:(CLBApiClientCompletionBlock)completion {
    return [self uploadImage:image url:urlString parameters:body progress:progress completion:completion retryCount:0];
}

-(NSURLSessionDataTask*)uploadFile:(NSURL *)fileUrl
                               url:(NSString *)urlString
                        parameters:(NSDictionary*)parameters
                          progress:(CLBApiClientUploadProgressBlock)progress
                        completion:(CLBApiClientCompletionBlock)completion
                        retryCount:(int)retryCount {
    __weak typeof(self) weakSelf = self;
    
    return [super uploadFile:fileUrl url:urlString parameters:parameters progress:progress completion:^(NSURLSessionDataTask *task, NSError *error, id response) {
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf onRequestComplete:response error:error task:task retryCount:retryCount completion:completion retryBlock:^{
            [strongSelf uploadFile:fileUrl url:urlString parameters:parameters progress:progress completion:completion retryCount:retryCount + 1];
        }];
    }];
}

-(NSURLSessionDataTask*)uploadFile:(NSURL *)fileUrl
                               url:(NSString *)urlString
                        parameters:(NSDictionary*)parameters
                          progress:(CLBApiClientUploadProgressBlock)progress
                        completion:(CLBApiClientCompletionBlock)completion {
    return [self uploadFile:fileUrl url:urlString parameters:parameters progress:progress completion:completion retryCount:0];
}

- (NSURLSessionDataTask *)requestWithMethod:(NSString*)method
                                        url:(NSString *)URLString
                                 parameters:(id)parameters
                                 completion:(CLBApiClientCompletionBlock)completion
                                 retryCount:(int)retryCount {
    __weak typeof(self) weakSelf = self;
    
    return [super requestWithMethod:method url:URLString parameters:parameters completion:^(NSURLSessionDataTask *task, NSError *error, id response) {
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf onRequestComplete:response error:error task:task retryCount:retryCount completion:completion retryBlock:^{
            [strongSelf requestWithMethod:method url:URLString parameters:parameters completion:completion retryCount:retryCount + 1];
        }];
    }];
}

- (NSURLSessionDataTask *)requestWithMethod:(NSString*)method
                                        url:(NSString *)URLString
                                 parameters:(id)parameters
                                 completion:(CLBApiClientCompletionBlock)completion {
    return [self requestWithMethod:method url:URLString parameters:parameters completion:completion retryCount:0];
}

@end
