//
//  CLBImageLoader.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBImageLoader.h"
#import "CLBUtility.h"

@interface CLBImageLoadRequest : NSObject

@property NSString* url;
@property NSMutableArray* completionBlocks;

@end

@implementation CLBImageLoadRequest
@end

@interface CLBImageLoader()

@property NSMutableArray* queuedRequests;
@property CLBImageLoadRequest* activeRequest;
@property NSCache* imageCache;

@end

@implementation CLBImageLoader

- (instancetype)initWithStrategy:(id<CLBImageLoaderStrategy>)strategy {
    self = [super init];
    if (self) {
        _strategy = strategy;
        _queuedRequests = [NSMutableArray new];
        _imageCache = [[NSCache alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)loadImageForUrl:(NSString *)urlString withCompletion:(CLBImageLoaderCompletionBlock)completion {
    if(completion == nil){
        return;
    }else if(urlString == nil){
        completion(nil);
        return;
    }

    if([self.imageCache objectForKey:urlString] == nil){
        CLBImageLoadRequest* request = [[CLBImageLoadRequest alloc] init];
        request.url = urlString;
        request.completionBlocks = [NSMutableArray arrayWithObject:completion];

        [self queueRequest:request];
    }else{
        completion([self.imageCache objectForKey:urlString]);
    }
}

-(void)queueRequest:(CLBImageLoadRequest*)request {
    @synchronized(self){
        // Do not request the same URL twice, just add the completion handler to the existing request
        CLBImageLoadRequest* existingRequest;
        if([self.activeRequest.url isEqualToString:request.url]){
            existingRequest = self.activeRequest;
        }else{
            existingRequest = [self queuedRequestForUrl:request.url];
        }

        if(existingRequest){
            [existingRequest.completionBlocks addObjectsFromArray:request.completionBlocks];
        }else{
            [self.queuedRequests addObject:request];
            [self dequeueAndPerformRequest];
        }
    }
}

-(void)dequeueAndPerformRequest {
    @synchronized(self){
        if(self.activeRequest == nil && self.queuedRequests.count > 0){
            self.activeRequest = self.queuedRequests.firstObject;
            [self.queuedRequests removeObject:self.activeRequest];

            if([self.imageCache objectForKey:self.activeRequest.url] == nil){
                __weak typeof(self) weakSelf = self;
                [self.strategy loadImageForUrl:self.activeRequest.url withCompletion:^(UIImage *image) {
                    __strong typeof(self) strongSelf = weakSelf;
                    if(image && strongSelf.activeRequest.url){
                        [strongSelf.imageCache setObject:image forKey:strongSelf.activeRequest.url];
                    }
                    [strongSelf completeRequestWithImage:image];
                }];
            }else{
                [self completeRequestWithImage:[self.imageCache objectForKey:self.activeRequest.url]];
            }
        }
    }
}

-(void)completeRequestWithImage:(UIImage*)image {
    @synchronized(self){
        CLBImageLoadRequest* completedRequest = self.activeRequest;
        CLBEnsureMainThread(^{
            for(CLBImageLoaderCompletionBlock completionBlock in completedRequest.completionBlocks){
                completionBlock(image);
            }
        });

        self.activeRequest = nil;
        [self dequeueAndPerformRequest];
    }
}

-(CLBImageLoadRequest*)queuedRequestForUrl:(NSString*)url {
    for(CLBImageLoadRequest* queuedRequest in self.queuedRequests){
        if([queuedRequest.url isEqualToString:url]){
            return queuedRequest;
        }
    }
    return nil;
}

-(void)cacheImage:(UIImage *)image forUrl:(NSString *)urlString {
    if(image && urlString){
        [self.imageCache setObject:image forKey:urlString];
    }
}

-(UIImage*)cachedImageForUrl:(NSString *)urlString {
    return [self.imageCache objectForKey:urlString];
}

-(void)clearImageCache {
    [self.imageCache removeAllObjects];
}

-(void)didReceiveMemoryWarning {
    [self clearImageCache];
}

-(void)cancelRequestForURL:(NSString *)urlString {
    if (urlString && urlString.length > 0 && self.queuedRequests) {
        for (CLBImageLoadRequest *request in self.queuedRequests) {
            if ([request.url isEqualToString:urlString] && [request.completionBlocks count] == 1) {
                [self.queuedRequests removeObject:request];
                return;
            }
        }
    }
}

@end
