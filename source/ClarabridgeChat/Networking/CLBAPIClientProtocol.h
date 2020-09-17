//
//  CLBAPIClientProtocol.h
//  ClarabridgeChat
//
//  Created by Shona Nunez on 11/02/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^CLBApiClientCompletionBlock)(NSURLSessionDataTask * _Nullable task, NSError * _Nullable error, id _Nullable responseObject);
typedef void (^CLBApiClientUploadProgressBlock)(double progress);

@protocol CLBAPIClientProtocol <NSObject>

- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(id _Nullable)parameters
                   completion:(CLBApiClientCompletionBlock)completion;

- (NSURLSessionUploadTask *)uploadImage:(UIImage *)image
                                   url:(NSString *)urlString
                            completion:(CLBApiClientCompletionBlock)completion;

- (NSURLSessionDataTask *)uploadImage:(UIImage *)image
                                  url:(NSString *)urlString
                           parameters:(NSDictionary * _Nullable)body
                             progress:(CLBApiClientUploadProgressBlock _Nullable)progress
                           completion:(CLBApiClientCompletionBlock)completion;

- (NSURLSessionDataTask *)uploadFile:(NSURL *)fileUrl
                                 url:(NSString *)urlString
                          parameters:(NSDictionary * _Nullable)parameters
                            progress:(CLBApiClientUploadProgressBlock _Nullable)progress
                          completion:(CLBApiClientCompletionBlock)completion;

- (NSURLSessionDataTask *)requestWithMethod:(NSString *)method
                                        url:(NSString *)URLString
                                 parameters:(id _Nullable)parameters
                                 completion:(CLBApiClientCompletionBlock _Nullable)completion;

@property NSURL *baseURL;

@end

NS_ASSUME_NONNULL_END
