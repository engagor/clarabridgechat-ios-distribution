//
//  CLBCoordinates.m
//  ClarabridgeChat
//

#import "CLBCoordinates.h"
#import "CLBCoordinates+Private.h"

@implementation CLBCoordinates

-(instancetype)initWithLatitude:(double)latitude longitude:(double)longitude {
    self = [super init];
    
    if (self) {
        self.latitude = [[NSNumber alloc] initWithDouble:latitude];
        self.longitude = [[NSNumber alloc] initWithDouble:longitude];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.latitude = [[NSNumber alloc] initWithDouble:[coder decodeDoubleForKey:@"latitude"]];
        self.longitude = [[NSNumber alloc] initWithDouble:[coder decodeDoubleForKey:@"longitude"]];
    }
    return self;
}

-(id)serialize {
    return @{@"lat": @([self.latitude doubleValue]), @"long": @([self.longitude doubleValue])};
}

-(void)deserialize:(NSDictionary*)object {
    self.latitude = [[NSNumber alloc] initWithDouble:[object[@"lat"] doubleValue]];
    self.longitude = [[NSNumber alloc] initWithDouble:[object[@"long"] doubleValue]];
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeDouble:[self.latitude doubleValue] forKey:@"latitude"];
    [coder encodeDouble:[self.longitude doubleValue] forKey:@"longitude"];
}

#pragma mark - NSCopying
-(id)copyWithZone:(NSZone *)zone {
    CLBCoordinates *coordinates = [[CLBCoordinates allocWithZone:zone] init];
    
    coordinates.latitude = self.latitude;
    coordinates.longitude = self.longitude;
    
    return coordinates;
}

@end
