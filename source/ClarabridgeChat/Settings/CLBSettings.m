//
//  CLBSettings.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBSettings.h"
#import "CLBSettings+Private.h"
#import "CLBUtility.h"
#import "ClarabridgeChat+Private.h"
#import "CLBUserLifecycleManager.h"

static const NSUInteger kDefaultNotificationTimeout = 8;
static NSString *const kValuePlaceholderReadFromPersistence = @"CLB_READ_LAST_KNOWN_VALUE";

NSString *const CLBMenuItemCamera = @"takePhoto";
NSString *const CLBMenuItemGallery = @"pickFromGallery";
NSString *const CLBMenuItemDocument = @"uploadDocument";
NSString *const CLBMenuItemLocation = @"shareLocation";

@interface CLBSettings()

@property(nonatomic, copy) NSString *configBaseUrl;
@property(nonatomic, copy) NSString *sessionToken;
@property(nonatomic, copy) NSString *userId;
@property(nonatomic, copy) NSString *externalId;
@property(nonatomic, copy) NSString *jwt;

@end

@implementation CLBSettings

+ (instancetype)settingsWithIntegrationId:(NSString *)integrationId {
    return [[CLBSettings alloc] initWithIntegrationId: integrationId];
}

+ (instancetype)settingsWithIntegrationId:(NSString *)integrationId andAuthCode:(NSString *)authCode {
    return [[CLBSettings alloc] initWithIntegrationId:integrationId andAuthCode:authCode];
}

- (instancetype)init {
    return [self initWithIntegrationId:nil];
}

- (instancetype)initWithIntegrationId:(NSString *)integrationId {
    self = [super init];
    if (self) {
        _integrationId = [integrationId copy];
        _conversationAccentColor = CLBDefaultAccentColor();
        _conversationAccentColorDarkMode = CLBDefaultAccentColor();
        _conversationListAccentColor = CLBDefaultAccentColor();
        _conversationStatusBarStyle = UIStatusBarStyleDefault;
        _conversationStatusBarStyleDarkMode = UIStatusBarStyleDefault;
        _notificationDisplayTime = kDefaultNotificationTimeout;
        _enableAppDelegateSwizzling = YES;
        _enableUserNotificationCenterDelegateOverride = YES;
        _requestPushPermissionOnFirstMessage = YES;
        _userMessageTextColor = CLBDefaultUserMessageTextColor();
        _userMessageTextColorDarkMode = CLBDefaultUserMessageTextColor();
        _externalId = kValuePlaceholderReadFromPersistence;
        _jwt = kValuePlaceholderReadFromPersistence;
        _userId = kValuePlaceholderReadFromPersistence;
        _sessionToken = kValuePlaceholderReadFromPersistence;
        _allowedMenuItems = @[CLBMenuItemCamera, CLBMenuItemGallery, CLBMenuItemDocument, CLBMenuItemLocation];
    }
    return self;
}

- (instancetype)initWithIntegrationId:(NSString *)integrationId andAuthCode:(NSString *)authCode {
    self = [self initWithIntegrationId:integrationId];
    if(self) {
        _authCode = [authCode copy];
    }
    return self;
}

- (void)setIntegrationId:(NSString *)integrationId {
    if(_integrationId){
        NSLog(@"<CLARABRIDGECHAT::ERROR> integration id may only be set once, and should be set at init time. New value \"%@\" will be ignored", integrationId);
    }else{
        _integrationId = [integrationId copy];
    }
}

- (void)setConfigBaseUrl:(NSString *)configBaseUrl {
    if(_configBaseUrl){
        NSLog(@"<CLARABRIDGECHAT::ERROR> Service URL may only be set once, and should be set at init time. New value \"%@\" will be ignored", configBaseUrl);
    }else{
        _configBaseUrl = [configBaseUrl copy];
    }
}

- (NSString *)userId {
    if ([_userId isEqualToString:kValuePlaceholderReadFromPersistence]) {
        _userId = [CLBUserLifecycleManager lastKnownUserIdForAppId:self.appId];
    }
    
    return _userId;
}

- (NSString *)sessionToken {
    if ([_sessionToken isEqualToString:kValuePlaceholderReadFromPersistence]) {
        _sessionToken = [CLBUserLifecycleManager lastKnownSessionTokenForAppId:self.appId];
    }
    
    return _sessionToken;
}

- (NSString *)externalId {
    if ([_externalId isEqualToString:kValuePlaceholderReadFromPersistence]) {
        _externalId = [CLBUserLifecycleManager lastKnownExternalIdForAppId:self.appId];
    }
    
    return _externalId;
}

- (NSString *)jwt {
    if ([_jwt isEqualToString:kValuePlaceholderReadFromPersistence]) {
        _jwt = [CLBUserLifecycleManager lastKnownJwtForAppId:self.appId];
    }
    
    return [_jwt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (BOOL)isAuthenticatedUser {
    return self.externalId && self.jwt;
}

@end
