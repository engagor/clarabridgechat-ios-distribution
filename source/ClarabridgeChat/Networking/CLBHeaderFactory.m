//
//  CLBHeaderFactory.m
//  ClarabridgeChat
//
//  Created by Alan O'Connor on 11/02/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBHeaderFactory.h"
#import "CLBUtility.h"
#import "ClarabridgeChat+Private.h"
#import "CLBSettings+Private.h"

static NSString *const CLBAcceptHeaderKey = @"Accept";
static NSString *const CLBAuthorizationKey = @"Authorization";

static NSString *const CLBCustomClarabridgeChatSDKKey = @"x-smooch-sdk";
static NSString *const CLBCustomClarabridgeChatClientIdKey = @"x-smooch-clientid";
static NSString *const CLBCustomClarabridgeChatAppNameKey = @"x-smooch-appname";
static NSString *const CLBCustomClarabridgeChatPushKey = @"x-smooch-push";
static NSString *const CLBCustomClarabridgeChatAppIdKey = @"x-smooch-appid";

static NSString *const CLBAcceptHeaderValue = @"application/json";

@implementation CLBHeaderFactory

+ (NSDictionary *)configAPIClientHeaders {
    return @{
        CLBAcceptHeaderKey: CLBAcceptHeaderValue,
        CLBCustomClarabridgeChatSDKKey: [NSString stringWithFormat:@"ios/%@/%@", VENDOR_ID, CLARABRIDGECHAT_VERSION],
        CLBCustomClarabridgeChatClientIdKey: CLBGetOrGenerateUniqueDeviceIdentifier(),
        CLBCustomClarabridgeChatAppNameKey: CLBGetAppDisplayName(),
        CLBCustomClarabridgeChatPushKey: CLBGetPushNotificationDeviceToken() ? @"enabled" : @"disabled"
    };
}

+ (NSDictionary *)defaultHeadersForAPIClient:(CLBSettings *)settings {
    return @{
        CLBAcceptHeaderKey: CLBAcceptHeaderValue,
        CLBCustomClarabridgeChatAppIdKey: settings.appId,
        CLBCustomClarabridgeChatSDKKey: [NSString stringWithFormat:@"ios/%@/%@", VENDOR_ID, CLARABRIDGECHAT_VERSION],
        CLBCustomClarabridgeChatClientIdKey: CLBGetOrGenerateUniqueDeviceIdentifier(),
        CLBCustomClarabridgeChatAppNameKey: CLBGetAppDisplayName(),
        CLBCustomClarabridgeChatPushKey: CLBGetPushNotificationDeviceToken() ? @"enabled" : @"disabled"
    };
}

+ (NSDictionary *)authHeadersForAPIClient:(CLBSettings *)settings {
    NSMutableDictionary* headerFields = [NSMutableDictionary dictionaryWithDictionary:[self defaultHeadersForAPIClient:settings]];

    // Check IDs before credentials, because IDs can be wiped if the app is installed
    // In that case, ignore the stored credentials, because the app should be in a fresh state
    BOOL hasUserId = settings.userId && settings.userId.length > 0;
    BOOL hasAppUserId = settings.appUserId && settings.appUserId.length > 0;

    if (hasUserId) {
        BOOL hasJwt = settings.jwt && settings.jwt.length > 0;

        if (hasJwt) {
            headerFields[CLBAuthorizationKey] = [NSString stringWithFormat:@"Bearer %@", settings.jwt];
        }
    } else if (hasAppUserId) {
        BOOL hasSessionToken = settings.sessionToken && settings.sessionToken.length > 0;

        if (hasSessionToken) {
            headerFields[CLBAuthorizationKey] = [NSString stringWithFormat:@"Basic %@", CLBEncodeSessionToken(settings.appUserId, settings.sessionToken)];
        }
    }

    return headerFields;
}

@end
