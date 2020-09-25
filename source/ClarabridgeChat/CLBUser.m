//
//  CLBUser.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBUser.h"
#import "CLBUser+Private.h"
#import "CLBUtility.h"
#import "ClarabridgeChat+Private.h"
#import "CLBInnerUser.h"
#import "CLBClientInfo.h"
#import "CLBPersistence.h"

NSString* const CLBUserNSUserDefaultsKey = @"CLBUserNSUserDefaultsKey";
const int CLBMaxUserPropertyKeyBytes = 100;
const int CLBMaxUserPropertyValueBytes = 800;

@interface CLBUser()

@property CLBInnerUser* localCopy;
@property CLBInnerUser* remoteCopy;
@property NSString* userId;
@property NSString* externalId;
@property BOOL conversationStarted;
@property BOOL hasPaymentInfo;
@property BOOL credentialRequired;
@property NSDictionary* cardInfo;
@property NSString *appId;
@property CLBUserSettings *settings;
@property NSArray<NSDictionary*>* clients;

@end

@implementation CLBUser

static CLBUser* SharedInstance = nil;

+(instancetype)currentUser {
	return SharedInstance;
}

+(void)setCurrentUser:(CLBUser*)user {
    SharedInstance = user;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _localCopy = [[CLBInnerUser alloc] init];
        _remoteCopy = [[CLBInnerUser alloc] init];
        _settings = [[CLBUserSettings alloc] init];
    }
    return self;
}

-(NSDictionary*)validateMetadata:(NSDictionary*)metadata {
    NSMutableDictionary* mutableMetadata = [metadata mutableCopy];

    for (id k in metadata) {
        id value = metadata[k];
        if(![k isKindOfClass: [NSString class]]){
            [mutableMetadata removeObjectForKey:k];
            NSLog(@"<CLARABRIDGECHAT::WARNING> Property keys must be of type NSString, got: \"%@\". Object will be removed : %@", [k class], k);

        } else if (!([value isKindOfClass:[NSString class]] ||
                    [value isKindOfClass:[NSNumber class]] ||
                    [value isKindOfClass:[NSDate class]])){
            NSLog(@"<CLARABRIDGECHAT::WARNING> Property values must be of type NSString, NSNumber, or NSDate, got \"%@\". Will use the object's description instead : %@", [value class], value);

            mutableMetadata[k] = [value description];
        } else {
            if([(NSString *)k lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > CLBMaxUserPropertyKeyBytes) {
                NSLog(@"<CLARABRIDGECHAT::WARNING> Property key \"%@\" exceeds max size, keys larger than %d bytes will be truncated", k, CLBMaxUserPropertyKeyBytes);
            }

            if ([value isKindOfClass:[NSString class]] &&
                [(NSString *)value lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > CLBMaxUserPropertyValueBytes) {
                NSLog(@"<CLARABRIDGECHAT::WARNING> Property value \"%@\" exceeds max size, values larger than %d bytes will be truncated", value, CLBMaxUserPropertyValueBytes);
            }
        }
    }

    return [mutableMetadata copy];
}

-(void)addMetadata:(NSDictionary *)metadata {
    NSDictionary* remoteMetadata = self.remoteCopy.metadata;
    metadata = [self validateMetadata:metadata];

    NSMutableDictionary* metadataToAdd = [NSMutableDictionary dictionary];
    for(NSString* key in metadata){
        id value = metadata[key];

        if([value isKindOfClass:[NSDate class]]){
            value = CLBISOStringFromDate(value);
        }

        if(![value isEqual:remoteMetadata[key]]){
            metadataToAdd[key] = value;
        }
    }

    [self.localCopy addMetadata:metadataToAdd];
    [self storeLocalMetadata];
}

-(NSString*)firstName {
    return self.localCopy.firstName ?: self.remoteCopy.firstName;
}

-(void)setFirstName:(NSString *)firstName {
    if(![firstName isEqualToString:self.remoteCopy.firstName]){
        self.localCopy.firstName = [firstName copy];
        [self storeLocalMetadata];
    }
}

-(NSDictionary*)metadata {
    NSMutableDictionary *mergedMetadata = [[NSMutableDictionary alloc] initWithDictionary:self.localCopy.metadata];
    [mergedMetadata addEntriesFromDictionary:self.remoteCopy.metadata];
    return mergedMetadata;
}

-(NSString*)lastName {
    return self.localCopy.lastName ?: self.remoteCopy.lastName;
}

-(void)setLastName:(NSString *)lastName {
    if(![lastName isEqualToString:self.remoteCopy.lastName]){
        self.localCopy.lastName = [lastName copy];
        [self storeLocalMetadata];
    }
}

-(NSString*)email {
    return self.localCopy.email ?: self.remoteCopy.email;
}

-(void)setEmail:(NSString *)email {
    if(![email isEqualToString:self.remoteCopy.email]){
        self.localCopy.email = [email copy];
        [self storeLocalMetadata];
    }
}

-(NSDate*)signedUpAt {
    NSString* dateString = self.localCopy.signedUpAt ?: self.remoteCopy.signedUpAt;
    return CLBDateFromISOString(dateString);
}

-(void)setSignedUpAt:(NSDate *)signedUpAt {
    NSString* dateString = CLBISOStringFromDate(signedUpAt);
    if(![dateString isEqualToString:self.remoteCopy.signedUpAt]){
        self.localCopy.signedUpAt = [dateString copy];
        [self storeLocalMetadata];
    }
}

-(NSString*)fullName {
    NSString* firstName = self.firstName;
    NSString* lastName = self.lastName;

    if(!firstName){
        if(lastName){
            return lastName;
        }else{
            return nil;
        }
    }

    NSMutableString* fullName = [NSMutableString stringWithString:firstName];
    if(lastName){
        [fullName appendFormat:@" %@", lastName];
    }
    return [fullName copy];
}

-(void)consolidateMetadata {
    if(self.localCopy.firstName != nil){
        self.remoteCopy.firstName = self.localCopy.firstName;
    }

    if(self.localCopy.lastName != nil){
        self.remoteCopy.lastName = self.localCopy.lastName;
    }

    if(self.localCopy.email != nil){
        self.remoteCopy.email = self.localCopy.email;
    }

    if(self.localCopy.signedUpAt != nil){
        self.remoteCopy.signedUpAt = self.localCopy.signedUpAt;
    }

    [self.remoteCopy addMetadata:self.localCopy.metadata];

    self.localCopy = [[CLBInnerUser alloc] init];

    [self storeLocalMetadata];
}

-(void)readLocalMetadata {
    [[CLBPersistence sharedPersistence] ensureProtectedDataAvailable:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary* props = [defaults objectForKey:CLBUserNSUserDefaultsKey];
        
        [self.localCopy deserialize:props];
    }];
}

-(void)storeLocalMetadata {
    [[CLBPersistence sharedPersistence] ensureProtectedDataAvailable:^{
        NSDictionary* props = [self.localCopy serialize];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:props forKey:CLBUserNSUserDefaultsKey];
        [defaults synchronize];
    }];
}

-(BOOL)isModified {
    BOOL firstNameChanged = self.localCopy.firstName && ![self.localCopy.firstName isEqualToString:self.remoteCopy.firstName];
    BOOL lastNameChanged = self.localCopy.lastName && ![self.localCopy.lastName isEqualToString:self.remoteCopy.lastName];
    BOOL emailChanged = self.localCopy.email && ![self.localCopy.email isEqualToString:self.remoteCopy.email];
    BOOL signedUpChanged = self.localCopy.signedUpAt && ![self.localCopy.signedUpAt isEqualToString:self.remoteCopy.signedUpAt];
    BOOL metadataChanged = NO;
    for(id key in self.localCopy.metadata){
        NSObject* remoteValue = self.remoteCopy.metadata[key];
        NSObject* localValue = self.localCopy.metadata[key];

        if(!remoteValue || ![localValue isEqual:remoteValue]){
            metadataChanged = YES;
            break;
        }
    }

    return firstNameChanged || lastNameChanged || emailChanged || metadataChanged || signedUpChanged;
}

-(void)removeRedundancyFromLocalObject {
    if([self.localCopy.firstName isEqualToString:self.remoteCopy.firstName]){
        self.localCopy.firstName = nil;
    }

    if([self.localCopy.lastName isEqualToString:self.remoteCopy.lastName]){
        self.localCopy.lastName = nil;
    }

    if([self.localCopy.email isEqualToString:self.remoteCopy.email]){
        self.localCopy.email = nil;
    }

    if([self.localCopy.signedUpAt isEqualToString:self.remoteCopy.signedUpAt]){
        self.localCopy.signedUpAt = nil;
    }

    NSMutableDictionary* mutableLocalProps = [self.localCopy.metadata mutableCopy];
    for(id key in self.localCopy.metadata){
        NSObject* remoteValue = self.remoteCopy.metadata[key];
        NSObject* localValue = self.localCopy.metadata[key];

        if(remoteValue && [localValue isEqual:remoteValue]){
            [mutableLocalProps removeObjectForKey:key];
        }
    }
    self.localCopy.metadata = mutableLocalProps;
}

-(void)clearLocalMetadata {
    [self.localCopy clearMetadata];
}

#pragma mark - CLBRemoteObject

-(id)serialize {
    NSMutableDictionary *serialized = [[NSMutableDictionary alloc] initWithDictionary:[self.localCopy serialize]];

    if (!self.userId) {
        serialized[@"userId"] = self.externalId;
        // We're creating a new user, add device info
        serialized[@"client"] = [CLBClientInfo serializedClientInfo];
    }

    return serialized;
}

-(void)deserialize:(NSDictionary *)object {
    NSDictionary* appUser = object[@"appUser"];
    if(!appUser){
        return;
    }

    self.userId = appUser[@"_id"] ?: self.userId;
    self.externalId = appUser[@"userId"] ?: self.externalId;
    self.conversationStarted = [appUser[@"conversationStarted"] boolValue];
    self.hasPaymentInfo = [appUser[@"hasPaymentInfo"] boolValue];
    self.credentialRequired = [appUser[@"credentialRequired"] boolValue];
    self.clients = appUser[@"clients"];

    [self.settings deserialize:object[@"settings"]];

    [self.remoteCopy deserialize:appUser];
}

-(NSString*)remotePath {
    return [NSString stringWithFormat:@"/v2/apps/%@/appusers/%@", self.appId, self.userId];
}

-(NSString*)synchronizeMethod {
    return @"PUT";
}

@end
