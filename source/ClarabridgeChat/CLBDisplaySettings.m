//
//  CLBDisplaySettings.m
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBDisplaySettings+Private.h"

NSString* const CLBImageAspectRatioHorizontal = @"horizontal";
NSString* const CLBImageAspectRatioSquare = @"square";

static NSString* const kImageAspectRatioKey = @"imageAspectRatio";

@implementation CLBDisplaySettings

-(instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [self init];
    
    if (self) {
        _imageAspectRatio = dictionary[kImageAspectRatioKey] ?: CLBImageAspectRatioHorizontal;
    }
    
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    
    if (self) {
        _imageAspectRatio = [aDecoder decodeObjectForKey:kImageAspectRatioKey];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.imageAspectRatio forKey:kImageAspectRatioKey];
}

-(id)serialize {
    return @{kImageAspectRatioKey: self.imageAspectRatio};
}

-(id)copyWithZone:(NSZone *)zone {
    CLBDisplaySettings *displaySettings = [[CLBDisplaySettings alloc] init];
    
    displaySettings.imageAspectRatio = [self.imageAspectRatio copy];
    
    return displaySettings;
}

@end
