//
//  CLBFileUploadMessage.h
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBSOMessage.h"

extern NSString* const CLBFileUploadMessageProgressDidChangeNotification;

@interface CLBFileUploadMessage : NSObject < CLBSOMessage >

-(instancetype)initWithMediaUrl:(NSString *)mediaUrl;
-(instancetype)initWithImage:(UIImage *)image;

@property (nonatomic) BOOL failed;
@property (nonatomic) double progress;

@end
