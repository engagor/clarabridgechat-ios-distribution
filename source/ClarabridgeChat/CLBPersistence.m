//
//  CLBPersistence.m
//  ClarabridgeChat
//
//  Created by Mike Spensieri on 2018-01-26.
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBPersistence.h"
#import "CLBUtility.h"

static NSString* const CLARABRIDGECHAT_KEYCHAIN_SERVICE_NAME = @"com.clarabridge";

@interface CLBPersistence()

@property UIApplication* application;

@end

@implementation CLBPersistence

static CLBPersistence* sharedInstance = nil;

+(instancetype)sharedPersistence {
    if (!sharedInstance) {
        sharedInstance = [[CLBPersistence alloc] initWithApplication:[UIApplication sharedApplication]];
    }
    
    return sharedInstance;
}

+(void)setSharedPersistence:(CLBPersistence*)persistence {
    sharedInstance = persistence;
}

-(instancetype)initWithApplication:(UIApplication*)application {
    self = [super init];
    if (self) {
        _application = application;
    }
    return self;
}

-(void)ensureProtectedDataAvailable:(void (^)(void))block {
    CLBEnsureMainThread(^{
        if(![self.application isProtectedDataAvailable]){
            return;
        }
        
        block();
    });
}

-(NSDictionary*)keychainQueryForValue:(NSString*)key forAccessibility:(CFStringRef)accessibility {
    return @{
             (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
             (__bridge id)kSecAttrAccessible: (__bridge id)accessibility,
             (__bridge id)kSecAttrService: CLARABRIDGECHAT_KEYCHAIN_SERVICE_NAME,
             (__bridge id)kSecAttrAccount: key,
             (__bridge id)kSecReturnData: (__bridge id)kCFBooleanTrue,
             (__bridge id)kSecReturnAttributes: (__bridge id)kCFBooleanTrue
             };
}

-(NSString*)getValueFromKeychain:(NSString*)key withAccessibility:(CFStringRef)accessibility {
    NSDictionary* keychainItem = [self keychainQueryForValue:key forAccessibility:accessibility];
    
    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, (CFTypeRef *)&result);
    
    if (status != noErr) {
        return nil;
    }
    
    NSDictionary *resultDict = (__bridge_transfer NSDictionary *)result;
    NSData *identifier = resultDict[(__bridge id)kSecValueData];
    
    return [[NSString alloc] initWithData:identifier encoding:NSUTF8StringEncoding];
}

-(NSString*)getValueFromKeychain:(NSString*)key {
    __block NSString* value;
    
    [self ensureProtectedDataAvailable:^{
        value = [self getValueFromKeychain:key withAccessibility:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
        
        if (!value || value.length == 0) {
            // Back compat, see if there is a value with the old accessibility value
            // If so, upgrade it to the new accessibility
            value = [self getValueFromKeychain:key withAccessibility:kSecAttrAccessibleAlwaysThisDeviceOnly];
            
            if (value && value.length > 0) {
                [self removeValueFromKeychain:key withAccessibility:kSecAttrAccessibleAlwaysThisDeviceOnly];
                [self persistValue:value inKeychain:key];
            }
        }
    }];
    
    return value.length > 0 ? value : nil;
}

-(NSString*)getValueFromUserDefaults:(NSString*)key {
    __block NSString* value;
    
    [self ensureProtectedDataAvailable:^{
        value = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    }];
    
    return value;
}

-(BOOL)persistValue:(NSString*)value inKeychain:(NSString*)key {
    __block BOOL result = NO;
    
    [self ensureProtectedDataAvailable:^{
        NSDictionary* keychainItem = @{
                                       (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                       (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                       (__bridge id)kSecAttrService: CLARABRIDGECHAT_KEYCHAIN_SERVICE_NAME,
                                       (__bridge id)kSecAttrAccount: key,
                                       (__bridge id)kSecValueData: [value dataUsingEncoding:NSUTF8StringEncoding]
                                       };
        
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)keychainItem, NULL);
        
        if (status == errSecDuplicateItem) {
            NSDictionary* update = @{
                                     (__bridge id)kSecValueData: [value dataUsingEncoding:NSUTF8StringEncoding]
                                     };
            
            status = SecItemUpdate((__bridge CFDictionaryRef)keychainItem, (__bridge CFDictionaryRef)update);
        }
        
        result = status == noErr;
    }];
    
    return result;
}

-(void)persistValue:(NSString*)value inUserDefaults:(NSString*)key {
    [self ensureProtectedDataAvailable:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:value forKey:key];
        [defaults synchronize];
    }];
}

-(BOOL)removeValueFromKeychain:(NSString*)key withAccessibility:(CFStringRef)accessibility {
    NSDictionary* keychainItem = @{
                                   (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                   (__bridge id)kSecAttrAccessible: (__bridge id)accessibility,
                                   (__bridge id)kSecAttrService: CLARABRIDGECHAT_KEYCHAIN_SERVICE_NAME,
                                   (__bridge id)kSecAttrAccount: key
                                   };
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)keychainItem);
    
    return status == noErr;
}

-(BOOL)removeValueFromKeychain:(NSString*)key {
    __block BOOL result = NO;
    
    [self ensureProtectedDataAvailable:^{
        result = [self removeValueFromKeychain:key withAccessibility:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
    }];
    
    return result;
}

-(void)removeValueFromUserDefaults:(NSString*)key {
    [self ensureProtectedDataAvailable:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:key];
        [defaults synchronize];
    }];
}

@end
