//
//  CLBFailedUpload.h
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLBFailedUpload : NSObject

@property (readonly) NSString *messageId;
@property (readonly) NSError *error;

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;

+(BOOL)isRetryableUploadError:(NSError *)error;

@end
