//
//  CLBFileUploadMessage.m
//  ClarabridgeChat
//
//  Created by Will Mora on 2018-03-02.
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBFileUploadMessage.h"

NSString* const CLBFileUploadMessageProgressDidChangeNotification = @"CLBFileUploadMessageProgressDidChangeNotification";

@implementation CLBFileUploadMessage

@synthesize mediaUrl = _mediaUrl,
messageId = _messageId,
mediaSize = _mediaSize,
image = _image,
type = _type,
date = _date,
failed = _failed;

@synthesize appUserId;
@synthesize userId;

-(instancetype)init {
    self = [super init];
    
    if (self) {
        _date = [NSDate date];
        _progress = 0.0;
    }
    
    return self;
}

-(instancetype)initWithMediaUrl:(NSString *)mediaUrl {
    self = [self init];
    if(self){
        _mediaUrl = mediaUrl;
    }
    return self;
}

-(instancetype)initWithImage:(UIImage *)image {
    self = [self init];
    if(self){
        _image = image;
        _type = @"image";
    }
    return self;
}

-(void)setText:(NSString *)text{}
-(NSString*)text {
    return nil;
}

-(void)setTextFallback:(NSString *)textFallback{}
-(NSString*)textFallback {
    return nil;
}

-(void)setDisplayName:(NSString *)text{}
-(NSString*)displayName {
    return nil;
}

-(void)setAvatarUrl:(NSString *)avatarUrl{}
-(NSString*)avatarUrl {
    return nil;
}

-(void)setActions:(NSArray *)actions{}
-(NSArray*)actions {
    return nil;
}

-(void)setItems:(NSArray *)items{}
-(NSArray*)items {
    return nil;
}

-(void)setImageAspectRatio:(NSString *)type{}
-(NSString*)imageAspectRatio {
    return nil;
}

-(void)setIsFromCurrentUser:(BOOL)isFromCurrentUser{}
-(BOOL)isFromCurrentUser {
    return YES;
}

-(void)setSent:(BOOL)sent{}
-(BOOL)sent {
    return NO;
}

-(void)setIsRead:(BOOL)isRead{}
-(BOOL)isRead {
    return NO;
}

-(void)setLastRead:(NSDate *)lastRead{}
-(NSDate *)lastRead {
    return nil;
}

-(void)setProgress:(double)progress {
    _progress = progress;
    [[NSNotificationCenter defaultCenter] postNotificationName:CLBFileUploadMessageProgressDidChangeNotification object:self];
}

@end
