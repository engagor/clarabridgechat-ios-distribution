//
//  CLBQueryStringSerializer.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBQueryStringSerializer.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "CLBUtility.h"

static const CGFloat kImageMaxSize = 1280;
static const CGFloat kImageJPEGCompressionQuality = 0.75;

static NSString * CLBAFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding);

static NSString * CLBAFCreateMultipartFormBoundary() {
    return [NSString stringWithFormat:@"Boundary+%08X%08X", arc4random(), arc4random()];
}

static NSString * const kCLBAFMultipartFormCRLF = @"\r\n";

@implementation CLBQueryStringSerializer

-(NSString*)queryStringFromParams:(id)parameters {
    NSParameterAssert(parameters);
    return CLBAFQueryStringFromParametersWithEncoding(parameters, NSUTF8StringEncoding);
}

-(NSData*)serializeRequest:(NSMutableURLRequest *)request withParameters:(id)parameters error:(NSError *__autoreleasing *)error {
    if(parameters){
        if([[request HTTPMethod] isEqualToString:@"GET"]){
            [self addQueryStringToRequest:request withParameters:parameters];
            return nil;
        }else{
            if (![request valueForHTTPHeaderField:@"Content-Type"]) {
                [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            }

            NSString* formData = [self queryStringFromParams:parameters];
            return [formData dataUsingEncoding:NSUTF8StringEncoding];
        }
    }

    return nil;
}

-(void)addQueryStringToRequest:(NSMutableURLRequest*)mutableRequest withParameters:(id)parameters {
    if(parameters){
        mutableRequest.URL = [NSURL URLWithString:[[mutableRequest.URL absoluteString] stringByAppendingFormat:mutableRequest.URL.query ? @"&%@" : @"?%@", [self queryStringFromParams:parameters]]];
    }
}

-(NSData*)serializeRequest:(NSMutableURLRequest *)request withImage:(UIImage*)image fileUrl:(NSURL *)fileUrl parameters:(NSDictionary*)parameters error:(NSError *__autoreleasing *)error {
    NSData *fileData;
    NSString *fileContentType;
    NSString *filename;
    
    if (image) {
        fileData = UIImageJPEGRepresentation([self scaleDownImage:image], kImageJPEGCompressionQuality);
        fileContentType = @"image/jpeg";
        filename = @"image.jpg";
    } else if (fileUrl) {
        fileData = [NSData dataWithContentsOfURL:fileUrl];
        fileContentType = CLBContentTypeForPathExtension([fileUrl pathExtension]);
        filename = [fileUrl lastPathComponent];
    }
    
    if(!fileData || fileData.length == 0){
        *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotDecodeRawData userInfo:nil];
        return nil;
    }

    NSString *boundary = CLBAFCreateMultipartFormBoundary();
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];

    NSMutableData *body = [NSMutableData data];

    for (NSString *param in parameters) {
        NSObject *parameterValue = parameters[param];
        [body appendData:[[NSString stringWithFormat:@"%@--%@%@", kCLBAFMultipartFormCRLF, boundary, kCLBAFMultipartFormCRLF] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"%@", param, kCLBAFMultipartFormCRLF] dataUsingEncoding:NSUTF8StringEncoding]];
        if ([parameterValue isKindOfClass:[NSDictionary class]]) {
            [body appendData:[kCLBAFMultipartFormCRLF dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[NSJSONSerialization dataWithJSONObject:parameterValue options:0 error:error]];
        } else {
            [body appendData:[kCLBAFMultipartFormCRLF dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"%@", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }

    [body appendData:[[NSString stringWithFormat:@"%@--%@%@", kCLBAFMultipartFormCRLF, boundary, kCLBAFMultipartFormCRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"source\"; filename=\"%@\"%@", filename, kCLBAFMultipartFormCRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: %@%@%@", fileContentType, kCLBAFMultipartFormCRLF, kCLBAFMultipartFormCRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:fileData];
    [body appendData:[[NSString stringWithFormat:@"%@--%@--%@", kCLBAFMultipartFormCRLF, boundary, kCLBAFMultipartFormCRLF] dataUsingEncoding:NSUTF8StringEncoding]];

    if(body && body.length > 0){
        return body;
    }else{
        *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotDecodeRawData userInfo:nil];
        return  nil;
    }
}

-(UIImage*)scaleDownImage:(UIImage*)image {
    const CGFloat maxSize = kImageMaxSize;
    CGFloat scaleFactor;

    CGSize imageSize = image.size;
    if(imageSize.width > imageSize.height){
        if(imageSize.width <= maxSize){
            return image;
        }

        scaleFactor = (maxSize / imageSize.width);
    }else{
        if(imageSize.height <= maxSize){
            return image;
        }

        scaleFactor = (maxSize / imageSize.height);
    }

    CGSize newSize = CGSizeMake(imageSize.width * scaleFactor, imageSize.height * scaleFactor);

    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end

#pragma mark - Query String Creation (Stolen from AFNetworking)

@interface CLBAFQueryStringPair : NSObject

@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (id)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;

@end

NSArray * CLBAFQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = [dictionary objectForKey:nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:CLBAFQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:CLBAFQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:CLBAFQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[CLBAFQueryStringPair alloc] initWithField:key value:value]];
    }

    return mutableQueryStringComponents;
}

NSArray * CLBAFQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return CLBAFQueryStringPairsFromKeyAndValue(nil, dictionary);
}

static NSString * CLBAFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (CLBAFQueryStringPair *pair in CLBAFQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValueWithEncoding:stringEncoding]];
    }

    return [mutablePairs componentsJoinedByString:@"&"];
}

static NSString * const kCLBkAFCharactersToBeEscapedInQueryString = @":/?&=;+!@#$()',*";

static NSString * CLBAFPercentEscapedQueryStringValueFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)kCLBkAFCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

static NSString * CLBAFPercentEscapedQueryStringKeyFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kCLBkAFCharactersToLeaveUnescapedInQueryStringPairKey = @"[].";

    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kCLBkAFCharactersToLeaveUnescapedInQueryStringPairKey, (__bridge CFStringRef)kCLBkAFCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

@implementation CLBAFQueryStringPair

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (self) {
        _field = field;
        _value = value;
    }
    return self;
}

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return CLBAFPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding);
    } else {
        return [NSString stringWithFormat:@"%@=%@", CLBAFPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding), CLBAFPercentEscapedQueryStringValueFromStringWithEncoding([self.value description], stringEncoding)];
    }
}

@end
