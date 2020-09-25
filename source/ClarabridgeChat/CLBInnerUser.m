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

@property NSMutableDictionary* innerMetadata;

@end

@implementation CLBInnerUser

- (instancetype)init {
    self = [super init];
    if (self) {
        _innerMetadata = [NSMutableDictionary dictionary];
    }
    return self;
}

-(NSDictionary*)metadata {
    return [self.innerMetadata copy];
}

-(void)setMetadata:(NSDictionary *)metadata {
    self.innerMetadata = [metadata mutableCopy];
}

-(void)addMetadata:(NSDictionary *)metadata {
    [self.innerMetadata addEntriesFromDictionary:metadata];
}

-(NSDictionary*)serialize {
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:@{ @"properties" : [self.innerMetadata copy] }];

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
    self.innerMetadata = [object[@"properties"] mutableCopy] ?: [NSMutableDictionary dictionary];
}

-(void)clearMetadata {
    [self.innerMetadata removeAllObjects];
}

@end
