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
@property NSString* appUserId;
@property NSString* userId;
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

-(NSDictionary*)validateProperties:(NSDictionary*)properties {
    NSMutableDictionary* mutableProperties = [properties mutableCopy];

    for (id k in properties) {
        id value = properties[k];
        if(![k isKindOfClass: [NSString class]]){
            [mutableProperties removeObjectForKey:k];
            NSLog(@"<CLARABRIDGECHAT::WARNING> Property keys must be of type NSString, got: \"%@\". Object will be removed : %@", [k class], k);

        } else if (!([value isKindOfClass:[NSString class]] ||
                    [value isKindOfClass:[NSNumber class]] ||
                    [value isKindOfClass:[NSDate class]])){
            NSLog(@"<CLARABRIDGECHAT::WARNING> Property values must be of type NSString, NSNumber, or NSDate, got \"%@\". Will use the object's description instead : %@", [value class], value);

            mutableProperties[k] = [value description];
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

    return [mutableProperties copy];
}

-(void)addProperties:(NSDictionary *)properties {
    NSDictionary* remoteProperties = self.remoteCopy.properties;
    properties = [self validateProperties:properties];

    NSMutableDictionary* propertiesToAdd = [NSMutableDictionary dictionary];
    for(NSString* key in properties){
        id value = properties[key];

        if([value isKindOfClass:[NSDate class]]){
            value = CLBISOStringFromDate(value);
        }

        if(![value isEqual:remoteProperties[key]]){
            propertiesToAdd[key] = value;
        }
    }

    [self.localCopy addProperties:propertiesToAdd];
    [self storeLocalProperties];
}

-(NSString*)firstName {
    return self.localCopy.firstName ?: self.remoteCopy.firstName;
}

-(void)setFirstName:(NSString *)firstName {
    if(![firstName isEqualToString:self.remoteCopy.firstName]){
        self.localCopy.firstName = [firstName copy];
        [self storeLocalProperties];
    }
}

-(NSDictionary*)properties {
    NSMutableDictionary *mergedProperties = [[NSMutableDictionary alloc] initWithDictionary:self.localCopy.properties];
    [mergedProperties addEntriesFromDictionary:self.remoteCopy.properties];
    return mergedProperties;
}

-(NSString*)lastName {
    return self.localCopy.lastName ?: self.remoteCopy.lastName;
}

-(void)setLastName:(NSString *)lastName {
    if(![lastName isEqualToString:self.remoteCopy.lastName]){
        self.localCopy.lastName = [lastName copy];
        [self storeLocalProperties];
    }
}

-(NSString*)email {
    return self.localCopy.email ?: self.remoteCopy.email;
}

-(void)setEmail:(NSString *)email {
    if(![email isEqualToString:self.remoteCopy.email]){
        self.localCopy.email = [email copy];
        [self storeLocalProperties];
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
        [self storeLocalProperties];
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

-(void)consolidateProperties {
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

    [self.remoteCopy addProperties:self.localCopy.properties];

    self.localCopy = [[CLBInnerUser alloc] init];

    [self storeLocalProperties];
}

-(void)readLocalProperties {
    [[CLBPersistence sharedPersistence] ensureProtectedDataAvailable:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary* props = [defaults objectForKey:CLBUserNSUserDefaultsKey];
        
        [self.localCopy deserialize:props];
    }];
}

-(void)storeLocalProperties {
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
    BOOL propertiesChanged = NO;
    for(id key in self.localCopy.properties){
        NSObject* remoteValue = self.remoteCopy.properties[key];
        NSObject* localValue = self.localCopy.properties[key];

        if(!remoteValue || ![localValue isEqual:remoteValue]){
            propertiesChanged = YES;
            break;
        }
    }

    return firstNameChanged || lastNameChanged || emailChanged || propertiesChanged || signedUpChanged;
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

    NSMutableDictionary* mutableLocalProps = [self.localCopy.properties mutableCopy];
    for(id key in self.localCopy.properties){
        NSObject* remoteValue = self.remoteCopy.properties[key];
        NSObject* localValue = self.localCopy.properties[key];

        if(remoteValue && [localValue isEqual:remoteValue]){
            [mutableLocalProps removeObjectForKey:key];
        }
    }
    self.localCopy.properties = mutableLocalProps;
}

-(void)clearLocalProperties {
    [self.localCopy clearProperties];
}

#pragma mark - CLBRemoteObject

-(id)serialize {
    NSMutableDictionary *serialized = [[NSMutableDictionary alloc] initWithDictionary:[self.localCopy serialize]];

    if (!self.appUserId) {
        serialized[@"userId"] = self.userId;
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

    self.appUserId = appUser[@"_id"] ?: self.appUserId;
    self.userId = appUser[@"userId"] ?: self.userId;
    self.conversationStarted = [appUser[@"conversationStarted"] boolValue];
    self.hasPaymentInfo = [appUser[@"hasPaymentInfo"] boolValue];
    self.credentialRequired = [appUser[@"credentialRequired"] boolValue];
    self.clients = appUser[@"clients"];

    [self.settings deserialize:object[@"settings"]];

    [self.remoteCopy deserialize:appUser];
}

-(NSString*)remotePath {
    return [NSString stringWithFormat:@"/v2/apps/%@/appusers/%@", self.appId, self.appUserId];
}

-(NSString*)synchronizeMethod {
    return @"PUT";
}

@end
