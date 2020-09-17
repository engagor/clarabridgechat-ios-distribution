//
//  CLBFailedUpload.m
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBFailedUpload.h"
#import "CLBLocalization.h"
#import "CLBMessage+Private.h"
#import "ClarabridgeChat.h"

NSString * const CLBFailedUploadInvalidFileCode = @"invalid_file";
NSString * const CLBFailedUploadVirusDetectedCode = @"virus_detected";
NSInteger const CLBFailedUploadEntityTooLargeStatusCode = 413;
NSInteger const CLBFailedUploadUnsupportedfMediaTypeStatusCode = 415;

@implementation CLBFailedUpload

-(instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    
    if (self) {
        _messageId = dictionary[@"data"][@"messageId"];
        NSDictionary *errorDict = dictionary[@"err"];
        
        NSInteger statusCode = errorDict[@"status"] ? [errorDict[@"status"] integerValue] : 400;
        NSString *errorCode = errorDict[@"code"];
        NSString *errorMessage = [CLBLocalization localizedStringForKey:@"Invalid file"];
        
        if ([errorCode isEqualToString:CLBFailedUploadVirusDetectedCode]) {
            errorMessage = [CLBLocalization localizedStringForKey:@"A virus was detected in your file and it has been rejected"];
        } else if (statusCode == CLBFailedUploadUnsupportedfMediaTypeStatusCode) {
            errorMessage = [CLBLocalization localizedStringForKey:@"Unsupported file type"];
        }  else if (statusCode == CLBFailedUploadEntityTooLargeStatusCode) {
            NSString *readableMaxSize = [NSByteCountFormatter stringFromByteCount:CLBMessageFileSizeLimit
                                                                       countStyle:NSByteCountFormatterCountStyleFile];
            errorMessage = [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"Max file size limit exceeded %@."], readableMaxSize];
        }
        
        if (!errorCode || [errorCode isEqualToString:@""]) {
            errorCode = CLBFailedUploadInvalidFileCode;
        }
        
        NSDictionary *userInfo = @{CLBErrorDescriptionIdentifier: errorMessage, CLBErrorCodeIdentifier: errorCode};
        _error = [NSError errorWithDomain:CLBErrorDomainIdentifier code:statusCode userInfo:userInfo];
    }
    
    return self;
}

+(BOOL)isRetryableUploadError:(NSError *)error {
    return error.code != CLBFailedUploadEntityTooLargeStatusCode && error.code != CLBFailedUploadUnsupportedfMediaTypeStatusCode && ![error.userInfo[CLBErrorCodeIdentifier] isEqualToString:CLBFailedUploadVirusDetectedCode];
}

@end
