//
//  CLBInnerUser.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBInnerUser.h"
#import "CLBUtility.h"

static NSString* const kFirstNameKey = @"givenName";
static NSString* const kLastNameKey = @"surname";
static NSString* const kEmailKey = @"email";
static NSString* const kSignedUpAtKey = @"signedUpAt";

@interface CLBInnerUser()

@property NSMutableDictionary* innerProperties;

@end

@implementation CLBInnerUser

- (instancetype)init {
    self = [super init];
    if (self) {
        _innerProperties = [NSMutableDictionary dictionary];
    }
    return self;
}

-(NSDictionary*)properties {
    return [self.innerProperties copy];
}

-(void)setProperties:(NSDictionary *)properties {
    self.innerProperties = [properties mutableCopy];
}

-(void)addProperties:(NSDictionary *)properties {
    [self.innerProperties addEntriesFromDictionary:properties];
}

-(NSDictionary*)serialize {
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:@{ @"properties" : [self.innerProperties copy] }];

    if(self.firstName){
        dict[kFirstNameKey] = self.firstName;
    }
    if(self.lastName){
        dict[kLastNameKey] = self.lastName;
    }
    if(self.email){
        dict[kEmailKey] = self.email;
    }
    if(self.signedUpAt){
        dict[kSignedUpAtKey] = self.signedUpAt;
    }

    return dict;
}

-(void)deserialize:(NSDictionary *)object {
    self.firstName = object[kFirstNameKey];
    self.lastName = object[kLastNameKey];
    self.email = object[kEmailKey];
    self.signedUpAt = object[kSignedUpAtKey];
    self.innerProperties = [object[@"properties"] mutableCopy] ?: [NSMutableDictionary dictionary];
}

-(void)clearProperties {
    [self.innerProperties removeAllObjects];
}

@end
