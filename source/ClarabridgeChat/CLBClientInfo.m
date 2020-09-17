//
//  CLBClientInfo.m
//  ClarabridgeChat
//
//  Copyright © 2017 Radialpoint. All rights reserved.
//

#import "CLBClientInfo.h"

#import <sys/sysctl.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "CLBBSMobileProvision.h"
#import "CLBUtility.h"
#import "ClarabridgeChat.h"
#import "CLBSettings+Private.h"

@implementation CLBClientInfo

+(NSDictionary *)serializedClientInfo {
    UIDevice* device = [UIDevice currentDevice];
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier* carrier = [networkInfo subscriberCellularProvider];

    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];

    NSString *installer = [CLBBSMobileProvision releaseModeString];

    NSMutableDictionary *serializedClientInfo = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                @"id": CLBGetUniqueDeviceIdentifier(),
                                                                                                @"appVersion": CLBStringOrNilString(CLBGetAppVersion()),
                                                                                                @"platform": @"ios",
                                                                                                @"integrationId": CLBStringOrNilString([ClarabridgeChat settings].integrationId),
                                                                                                @"info": @{
                                                                                                        @"os": CLBStringOrNilString([device systemName]),
                                                                                                        @"osVersion": CLBStringOrNilString([device systemVersion]),
                                                                                                        @"devicePlatform": CLBStringOrNilString(platform),
                                                                                                        @"appName": CLBStringOrNilString(CLBGetAppDisplayName()),
                                                                                                        @"buildNumber": CLBStringOrNilString([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]),
                                                                                                        @"carrier": CLBStringOrNilString(carrier.carrierName),
                                                                                                        @"appId" : CLBStringOrNilString([NSBundle mainBundle].bundleIdentifier),
                                                                                                        @"sdkVersion" : CLBStringOrNilString(CLARABRIDGECHAT_VERSION),
                                                                                                        @"vendor": CLBStringOrNilString(VENDOR_ID),
                                                                                                        @"installer" : CLBStringOrNilString(installer)
                                                                                                        }
                                                                                                }];

    NSString *pushNotificationToken = CLBGetPushNotificationDeviceToken();

    if (pushNotificationToken) {
        serializedClientInfo[@"pushNotificationToken"] = pushNotificationToken;
    }

    return serializedClientInfo;
}

@end
