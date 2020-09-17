//
//  CLBImageLoader.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CLBImageLoaderStrategy;

typedef void (^CLBImageLoaderCompletionBlock)(UIImage* image);

@interface CLBImageLoader : NSObject

-(instancetype)initWithStrategy:(id<CLBImageLoaderStrategy>)strategy;

-(void)loadImageForUrl:(NSString*)urlString withCompletion:(CLBImageLoaderCompletionBlock)completion;
-(void)cacheImage:(UIImage*)image forUrl:(NSString*)urlString;
-(UIImage*)cachedImageForUrl:(NSString*)urlString;
-(void)clearImageCache;

@property id<CLBImageLoaderStrategy> strategy;

@end

@protocol CLBImageLoaderStrategy <NSObject>

-(void)loadImageForUrl:(NSString*)urlString withCompletion:(CLBImageLoaderCompletionBlock)completion;

@end
