//
//  CLBUtility.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CLBConfig.h"
#import "CLBSettings+Private.h"

CGSize CLBAbsoluteScreenSize(void);
CGSize CLBOrientedScreenSize(void);

NSString* CLBGetAPIBaseUrlWithConfig(CLBConfig *config);
NSString* CLBGetConfigApiBaseUrlWithConfig(CLBConfig *config, CLBSettings *settings);
NSString* CLBGetRealtimeEndpointWithRealtimeSettings(CLBRealtimeSettings *settings);

BOOL CLBIsIOS9(void);
BOOL CLBIsIOS10OrLater(void);
BOOL CLBIsIOS11OrLater(void);

BOOL CLBIsTallScreenDevice(void);
BOOL CLBIsWideScreenDevice(void);
BOOL CLBIsExtraWideScreenDevice(void);
BOOL CLBIsIpad(void);
BOOL CLBIsLayoutPhoneInLandscape(void);
NSString* CLBStringOrNilString(NSString* string);
NSString* CLBStringFromBool(BOOL boolean);
CGFloat CLBStatusBarHeight(void);
CGFloat CLBNavBarHeight(void);
CGFloat CLBOffsetForStatusBar(void);
BOOL CLBIsNetworkAvailable(void);
UIViewController* CLBGetTopMostViewControllerOfRootWindow(void);
NSString* CLBGetAppDisplayName(void);
NSString* CLBGetAppVersion(void);
NSString* CLBGetPushNotificationDeviceToken(void);
void CLBSetPushNotificationDeviceToken(NSString* deviceToken);
BOOL CLBIsSimulator(void);
void CLBEnsureMainThread(void (^block)(void));

NSString* CLBGetUniqueDeviceIdentifier(void);
NSString* CLBGetOrGenerateUniqueDeviceIdentifier(void);
NSString* CLBGetLegacyUniqueDeviceIdentifier(void);
void CLBUpgradeLegacyUniqueDeviceIdentifier(void);

NSDate* CLBDateFromISOString(NSString* dateString);
NSString* CLBISOStringFromDate(NSDate* date);

UIImage* CLBFancyCharacterAsImageWithColor(NSString* character, CGFloat fontSize, UIColor* fontColor);
UIColor* CLBColorFromHex(long hex);

UIColor* CLBDefaultAccentColor(void);
UIColor* CLBDefaultUserMessageTextColor(void);
UIColor* CLBRedColor(void);
UIColor* CLBExtraLightGrayColor(BOOL supportDarkMode);
UIColor* CLBLightGrayColor(void);
UIColor* CLBMediumGrayColor(void);
UIColor* CLBDarkGrayColor(BOOL supportDarkMode);
UIColor* CLBExtraDarkGrayColor(BOOL supportDarkMode);
UIColor* CLBSaturatedColorForColor(UIColor *color);
UIColor* CLBSystemBackgroundColor(void);
UIColor* CLBNavBarItemTextColor(void);
UIColor* CLBWebviewBackgroundColor(void);
UIColor* CLBLabelColor(void);
UIColor* CLBSecondaryLabelColor(void);
UIBlurEffectStyle CLBBlurEffectStyle(void);

NSString* CLBEncodeSessionToken(NSString *userId, NSString *sessionToken);

CGRect CLBSafeBoundsForView(UIView *view);
UIEdgeInsets CLBSafeAreaInsetsForView(UIView *view);

long long CLBSizeForFile(NSURL *fileLocation);
NSString *CLBContentTypeForPathExtension(NSString *extension);
NSString *CLBFilenameForURL(NSString *url);
NSURL *CLBURLForString(NSString *url);

void CLBOpenExternalURL(NSURL* url);

id CLBSanitizeNSNull(id value);

UIActivityIndicatorViewStyle CLBActivityIndicatorViewStyleWhite(void);
UIActivityIndicatorViewStyle CLBActivityIndicatorViewStyleGray(void);
