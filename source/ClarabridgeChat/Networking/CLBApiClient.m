//
//  CLBApiClient.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBApiClient.h"
#import "CLBJSONSerializer.h"
#import <UIKit/UIKit.h>
#import "CLBUtility.h"

NSString *const CLBErrorStatusCode = @"CLBErrorStatusCode";

@interface CLBApiClient() <NSURLSessionTaskDelegate>

@property NSURLSession *session;
@property NSString *userAgent;
@property NSMutableDictionary *progressBlocks;

@end

@implementation CLBApiClient

- (instancetype)init {
    return [self initWithBaseURL:nil];
}

- (instancetype)initWithBaseURL:(NSString *)url {
    self = [super init];
    if(self){
        _progressBlocks = [[NSMutableDictionary alloc] init];
        _baseURL = [NSURL URLWithString:url];
        _requestSerializer = [[CLBJSONSerializer alloc] init];
        _responseSerializer = (CLBJSONSerializer*)_requestSerializer;

        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];

        // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
        NSString *userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
        if (userAgent) {
            if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
                NSMutableString *mutableUserAgent = [userAgent mutableCopy];
                if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
                    userAgent = mutableUserAgent;
                }
            }
            
            _userAgent = userAgent;
        }
    }
    return self;
}

- (NSURLSessionDataTask*)GET:(NSString *)URLString parameters:(id)parameters completion:(CLBApiClientCompletionBlock)completion {
    return [self requestWithMethod:@"GET" url:URLString parameters:parameters completion:completion];
}

- (NSURLSessionDataTask*)requestWithMethod:(NSString *)method url:(NSString *)URLString parameters:(id)parameters completion:(CLBApiClientCompletionBlock)completion {
    return [self requestWithMethod:method url:URLString parameters:parameters image:nil fileUrl:nil completion:completion];
}

- (NSURLSessionDataTask*)uploadImage:(UIImage *)image url:(NSString *)urlString completion:(CLBApiClientCompletionBlock)completion {
    return [self uploadImage:image url:urlString parameters:nil progress:nil completion:completion];
}

- (NSURLSessionDataTask*)uploadImage:(UIImage *)image url:(NSString *)urlString parameters:(NSDictionary*)parameters progress:(CLBApiClientUploadProgressBlock)progress completion:(CLBApiClientCompletionBlock)completion {
    NSURLSessionDataTask* task = [self requestWithMethod:@"POST" url:urlString parameters:parameters image:image fileUrl:nil completion:completion];
    if(progress){
        [self.progressBlocks setObject:progress forKey:[NSString stringWithFormat:@"%ld", (unsigned long)task.taskIdentifier]];
    }
    return task;
}

- (NSURLSessionDataTask*)uploadFile:(NSURL *)fileUrl url:(NSString *)urlString parameters:(NSDictionary *)parameters progress:(CLBApiClientUploadProgressBlock)progress completion:(CLBApiClientCompletionBlock)completion {
    NSURLSessionDataTask* task = [self requestWithMethod:@"POST" url:urlString parameters:parameters image:nil fileUrl:fileUrl completion:completion];
    if(progress){
        [self.progressBlocks setObject:progress forKey:[NSString stringWithFormat:@"%ld", (unsigned long)task.taskIdentifier]];
    }
    return task;
}

- (NSURLSessionDataTask*)requestWithMethod:(NSString *)method url:(NSString *)URLString parameters:(id)parameters image:(UIImage*)image fileUrl:(NSURL *)fileUrl completion:(CLBApiClientCompletionBlock)completion {
    BOOL isMultipartRequest = image || fileUrl;
    
    NSMutableURLRequest* mutableRequest = [self newRequestWithMethod:method url:URLString];

    NSError* serializationError;

    NSData* bodyData;
    if(isMultipartRequest){
        bodyData = [self.requestSerializer serializeRequest:mutableRequest withImage:image fileUrl:fileUrl parameters:parameters error:&serializationError];
    }else{
        bodyData = [self.requestSerializer serializeRequest:mutableRequest withParameters:parameters error:&serializationError];
    }

    if(serializationError){
        if(completion){
            completion(nil, serializationError, nil);
        }
        return nil;
    }

    __block NSURLSessionDataTask* task;
    void (^doneBlock)(NSData *data, NSURLResponse *response, NSError *error) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        [self requestCompletedForTask:task withData:data response:(NSHTTPURLResponse*)response error:error completion:completion];
    };

    if(isMultipartRequest){
        task = [self.session uploadTaskWithRequest:mutableRequest fromData:bodyData completionHandler:doneBlock];
    }else{
        if(bodyData && bodyData.length > 0){
            mutableRequest.HTTPBody = bodyData;
        }
        task = [self.session dataTaskWithRequest:mutableRequest completionHandler:doneBlock];
    }

    [task resume];

    return task;
}

- (NSMutableURLRequest*)newRequestWithMethod:(NSString*)method url:(NSString*)urlString {
    BOOL isFullyQualifiedURL = [urlString rangeOfString:@"http://"].location != NSNotFound || [urlString rangeOfString:@"https://"].location != NSNotFound;

    NSURL *url;
    if(isFullyQualifiedURL){
        url = [NSURL URLWithString:urlString];
    }else{
        NSString *baseUrl = self.baseURL.absoluteString;

        if (baseUrl.length > 0 && [baseUrl hasSuffix:@"/"]) {
            baseUrl = [baseUrl substringToIndex:baseUrl.length - 1];
        }

        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseUrl, urlString]];
    }

    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    mutableRequest.HTTPMethod = method;

    NSDictionary* headerFields = self.headersBlock ? self.headersBlock() : @{};
    
    [headerFields enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![mutableRequest valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];
    
    if (self.userAgent && ![mutableRequest valueForHTTPHeaderField:@"User-Agent"]) {
        [mutableRequest setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    }

    return mutableRequest;
}

- (void)requestCompletedForTask:(NSURLSessionDataTask*)task withData:(NSData*)data response:(NSHTTPURLResponse*)response error:(NSError*)error completion:(CLBApiClientCompletionBlock)completion {
    [self.progressBlocks removeObjectForKey:[NSString stringWithFormat:@"%ld", (unsigned long)task.taskIdentifier]];

    if(!error && ![self isValidStatusCode:response]){
        NSInteger statusCode = response.statusCode;
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Bad status code : %ld %@",  (long)statusCode, [NSHTTPURLResponse localizedStringForStatusCode:statusCode]],
                                   CLBErrorStatusCode: [NSNumber numberWithInteger:statusCode]
                                   };

        error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
    }

    NSError* serializationError;
    id responseObject = [self.responseSerializer responseObjectForResponse:response data:data error:&serializationError];

    if(serializationError){
        error = serializationError;
        responseObject = nil;
    }

    if(completion){
        completion(task, error, responseObject);
    }
}

- (BOOL)isValidStatusCode:(NSHTTPURLResponse *)response {
    NSIndexSet* acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    return response && [acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode];
}

- (void)dealloc {
    [self.session invalidateAndCancel];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDataTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    NSString* taskIdentifier = [NSString stringWithFormat:@"%ld", (unsigned long)task.taskIdentifier];
    CLBApiClientUploadProgressBlock progressBlock = (CLBApiClientUploadProgressBlock)self.progressBlocks[taskIdentifier];

    if(progressBlock){
        CLBEnsureMainThread(^{
            progressBlock((double)totalBytesSent / (double)totalBytesExpectedToSend);
        });
    }
}

@end
