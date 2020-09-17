//
//  CLBAvatarImageLoaderStrategy.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBAvatarImageLoaderStrategy.h"

static const CGFloat kTimeoutInterval = 10;

@interface CLBAvatarImageLoaderStrategy() < NSURLConnectionDataDelegate, NSURLConnectionDelegate >

@property(copy) CLBImageLoaderCompletionBlock completion;
@property NSURLConnection* connection;
@property NSMutableData *data;

@end

@implementation CLBAvatarImageLoaderStrategy

-(void)dealloc {
    [self.connection cancel];
}

-(void)loadImageForUrl:(NSString *)urlString withCompletion:(CLBImageLoaderCompletionBlock)completion {
    self.completion = completion;

    NSURL* url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:kTimeoutInterval];
    NSURLConnection * connection = [[NSURLConnection alloc]
                                    initWithRequest:request
                                    delegate:self startImmediately:NO];

    [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [connection start];
}

- (void)connection:(__unused NSURLConnection *)connection didReceiveResponse:(__unused NSURLResponse *)response {
    self.data = [NSMutableData data];
}

- (void)connection:(__unused NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(__unused NSURLConnection *)connection {
    UIImage* image = [UIImage imageWithData:self.data];

    [self completeRequestWithImage:image];
}

- (void)connection:(__unused NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self completeRequestWithImage:nil];
}

-(void)completeRequestWithImage:(UIImage*)image {
    self.connection = nil;
    self.data = nil;

    if(self.completion){
        self.completion(image);
    }
}

@end
