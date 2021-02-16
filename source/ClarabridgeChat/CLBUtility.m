//
//  CLBUtility.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBUtility.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <arpa/inet.h>
#import "ClarabridgeChat+Private.h"
#import "CLBSettings+Private.h"
#import "CLBConfig.h"
#import "CLBPersistence.h"
#import <MobileCoreServices/MobileCoreServices.h>

// Legacy keys used for backwards compatibility. Do not change!
static NSString* const CLARABRIDGECHAT_LEGACY_UUID_DEFAULTS_KEY = @"CLARABRIDGECHAT_UUID_DEFAULTS_KEY";
static NSString* const CLARABRIDGECHAT_LEGACY_KEYCHAIN_ACCOUNT_NAME = @"CLARABRIDGECHAT_UUID_ACCOUNT";
static NSString* const CLARABRIDGECHAT_PUSH_NOTIFICATION_DEVICE_TOKEN_KEY = @"CLARABRIDGECHAT_PUSH_NOTIFICATION_DEVICE_TOKEN_KEY";
static NSString* const CLARABRIDGECHAT_MOST_RECENT_INTEGRATION_ID_KEY = @"CLARABRIDGECHAT_MOST_RECENT_INTEGRATION_ID_KEY";

static NSString* const CLARABRIDGECHAT_KEYCHAIN_SERVICE_NAME = @"com.clarabridge";
static NSString* const CLB_UNIQUE_DEVICE_IDENTIFIER_KEY = @"CLB_UNIQUE_DEVICE_IDENTIFIER_KEY";
static NSString* const CLB_UNIQUE_DEVICE_IDENTIFIER_ACCOUNT_NAME = @"CLB_UNIQUE_DEVICE_IDENTIFIER_ACCOUNT";

static const int CLARABRIDGECHAT_STATUS_BAR_HEIGHT = 20;
static const int CLARABRIDGECHAT_NAV_BAR_HEIGHT = 44;
static const int CLARABRIDGECHAT_NAV_BAR_HEIGHT_LANDSCAPE_IPHONE = 32;
static SCNetworkConnectionFlags CLARABRIDGECHAT_CONNECTION_FLAGS;
static SCNetworkReachabilityRef CLARABRIDGECHAT_REACHABILITY;

static const CGFloat kIPhone6Width = 375;
static const CGFloat kIPhone4Width = 320;
static const CGFloat kIPhone4Height = 480;

static NSDateFormatter* isoDateFormatter;

NSString* CLBGetAPIBaseUrlWithConfig(CLBConfig *config) {
    return  config.apiBaseUrl ?: @"";
}

NSString* CLBGetRealtimeEndpointWithRealtimeSettings(CLBRealtimeSettings *settings) {
    return  settings.baseUrl ?: @"";
}

NSString* CLBGetConfigApiBaseUrlWithConfig(CLBConfig *config, CLBSettings *settings) {
    if (settings.configBaseUrl) {
        return settings.configBaseUrl;
    }
    
    if (settings.region.length > 0) {
        return [NSString stringWithFormat:@"https://%@.config.%@.smooch.io", config.integrationId, settings.region];
    }
    
    return [NSString stringWithFormat:@"https://%@.config.smooch.io", config.integrationId];
}

BOOL CLBIsIOS9() {
    return (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_x_Max) && (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max);
}

BOOL CLBIsIOS10OrLater() {
    return (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max);
}

BOOL CLBIsIOS11OrLater() {
    if (@available(iOS 11.0, *)) {
        return YES;
    }
    
    return NO;
}

CGSize CLBAbsoluteScreenSize() {
    CGSize size = [UIScreen mainScreen].bounds.size;
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)){
        CGFloat t = size.width;
        size.width = size.height;
        size.height = t;
    }
    return size;
}

CGSize CLBOrientedScreenSize() {
    return [UIScreen mainScreen].bounds.size;
}

void CLBEnsureMainThread(void (^block)(void)) {
    if([[NSThread currentThread] isMainThread]){
        block();
    }else{
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

BOOL CLBIsTallScreenDevice() {
    return CLBAbsoluteScreenSize().height > kIPhone4Height;
}

BOOL CLBIsWideScreenDevice() {
    return CLBAbsoluteScreenSize().width > kIPhone4Width;
}

BOOL CLBIsExtraWideScreenDevice() {
    return CLBAbsoluteScreenSize().width > kIPhone6Width;
}

BOOL CLBIsIpad() {
   return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

BOOL CLBIsLayoutPhoneInLandscape() {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && !CLBIsIpad();
}

NSString* CLBStringOrNilString(NSString* string) {
    return string == nil ? @"nil" : string;
}

NSString* CLBStringFromBool(BOOL boolean) {
    return boolean ? @"YES" : @"NO";
}

NSString* CLBGetAppDisplayName() {
    NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    return appName ? appName : @"";
}

NSString* CLBGetAppVersion() {
    return [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
}

void saveUniqueIdentifierWithFallback(NSString* identifier) {
    BOOL success = [[CLBPersistence sharedPersistence] persistValue:identifier inKeychain:CLB_UNIQUE_DEVICE_IDENTIFIER_ACCOUNT_NAME];
    
    if(!success) {
        [[CLBPersistence sharedPersistence] persistValue:identifier inUserDefaults:CLB_UNIQUE_DEVICE_IDENTIFIER_KEY];
    }
}

static NSString* uniqueDeviceIdentifier;

NSString* CLBGetUniqueDeviceIdentifierInternal(BOOL generateNew) {
    if (uniqueDeviceIdentifier) {
        return uniqueDeviceIdentifier;
    }
    
    uniqueDeviceIdentifier = [[CLBPersistence sharedPersistence] getValueFromKeychain:CLB_UNIQUE_DEVICE_IDENTIFIER_ACCOUNT_NAME];
    
    if (!uniqueDeviceIdentifier || uniqueDeviceIdentifier.length == 0) {
        uniqueDeviceIdentifier = [[CLBPersistence sharedPersistence] getValueFromUserDefaults:CLB_UNIQUE_DEVICE_IDENTIFIER_KEY];
    }
    
    if (!uniqueDeviceIdentifier || uniqueDeviceIdentifier.length == 0) {
        uniqueDeviceIdentifier = CLBGetLegacyUniqueDeviceIdentifier();
    }
    
    if ((!uniqueDeviceIdentifier || uniqueDeviceIdentifier.length == 0) && generateNew) {
        // No stored value, craft a new identifier
        uniqueDeviceIdentifier = [[NSUUID UUID] UUIDString];
        
        saveUniqueIdentifierWithFallback(uniqueDeviceIdentifier);
    }
    
    return uniqueDeviceIdentifier;
}

NSString* CLBGetUniqueDeviceIdentifier() {
    return CLBGetUniqueDeviceIdentifierInternal(NO);
}

NSString* CLBGetOrGenerateUniqueDeviceIdentifier() {
    return CLBGetUniqueDeviceIdentifierInternal(YES);
}

NSString* CLBGetLegacyUniqueDeviceIdentifier() {
    NSString* identifier = [[CLBPersistence sharedPersistence] getValueFromKeychain:CLARABRIDGECHAT_LEGACY_KEYCHAIN_ACCOUNT_NAME];
    
    if (!identifier || identifier.length == 0) {
        identifier = [[CLBPersistence sharedPersistence] getValueFromUserDefaults:CLARABRIDGECHAT_LEGACY_UUID_DEFAULTS_KEY];
    }
    
    return identifier;
}

void CLBUpgradeLegacyUniqueDeviceIdentifier() {
    NSString* identifier = CLBGetLegacyUniqueDeviceIdentifier();

    if (identifier && identifier.length > 0) {
        saveUniqueIdentifierWithFallback(uniqueDeviceIdentifier);
        
        [[CLBPersistence sharedPersistence] removeValueFromUserDefaults:CLARABRIDGECHAT_LEGACY_UUID_DEFAULTS_KEY];
        [[CLBPersistence sharedPersistence] removeValueFromKeychain:CLARABRIDGECHAT_LEGACY_KEYCHAIN_ACCOUNT_NAME];
    }
}

NSString* CLBGetPushNotificationDeviceToken() {
    return [[CLBPersistence sharedPersistence] getValueFromUserDefaults:CLARABRIDGECHAT_PUSH_NOTIFICATION_DEVICE_TOKEN_KEY];
}

void CLBSetPushNotificationDeviceToken(NSString* deviceToken) {
    [[CLBPersistence sharedPersistence] persistValue:deviceToken inUserDefaults:CLARABRIDGECHAT_PUSH_NOTIFICATION_DEVICE_TOKEN_KEY];
}

NSString* CLBGetMostRecentIntegrationID() {
    return [[CLBPersistence sharedPersistence] getValueFromKeychain:CLARABRIDGECHAT_MOST_RECENT_INTEGRATION_ID_KEY];
}

void CLBSetMostRecentIntegrationID(NSString* integrationId) {
    [[CLBPersistence sharedPersistence] persistValue:integrationId inKeychain:CLARABRIDGECHAT_MOST_RECENT_INTEGRATION_ID_KEY];
}

CGFloat CLBStatusBarHeight() {
    if([[UIApplication sharedApplication] isStatusBarHidden]){
        return 0;
    }

    return CLARABRIDGECHAT_STATUS_BAR_HEIGHT;
}

CGFloat CLBNavBarHeight() {
    CGFloat height = CLARABRIDGECHAT_NAV_BAR_HEIGHT;

    if(CLBIsLayoutPhoneInLandscape() && !CLBIsExtraWideScreenDevice()){
        height = CLARABRIDGECHAT_NAV_BAR_HEIGHT_LANDSCAPE_IPHONE;
    }

    height += CLBStatusBarHeight();

    return height;
}

CGFloat CLBOffsetForStatusBar() {
    if(CLBIsIOS11OrLater()) {
        return CLBStatusBarHeight();
    }else{
        return 0;
    }
}

// Adapted from UIDevice-Reachability category
// https://github.com/erica/uidevice-extension/blob/master/UIDevice-Reachability.m
void CLBPingReachabilityInternal() {
	if (!CLARABRIDGECHAT_REACHABILITY)
	{
		BOOL ignoresAdHocWiFi = NO;
		struct sockaddr_in ipAddress;
		bzero(&ipAddress, sizeof(ipAddress));
		ipAddress.sin_len = sizeof(ipAddress);
		ipAddress.sin_family = AF_INET;
		ipAddress.sin_addr.s_addr = htonl(ignoresAdHocWiFi ? INADDR_ANY : IN_LINKLOCALNETNUM);

		CLARABRIDGECHAT_REACHABILITY = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (struct sockaddr *)&ipAddress);
		CFRetain(CLARABRIDGECHAT_REACHABILITY);
	}

	// Recover reachability flags
    SCNetworkReachabilityGetFlags(CLARABRIDGECHAT_REACHABILITY, &CLARABRIDGECHAT_CONNECTION_FLAGS);
}

BOOL CLBIsNetworkAvailable() {
	CLBPingReachabilityInternal();
	BOOL isReachable = ((CLARABRIDGECHAT_CONNECTION_FLAGS & kSCNetworkFlagsReachable) != 0);
    BOOL needsConnection = ((CLARABRIDGECHAT_CONNECTION_FLAGS & kSCNetworkFlagsConnectionRequired) != 0);
    return (isReachable && !needsConnection) ? YES : NO;
}

// Inspired from this StackOverflow answer: http://stackoverflow.com/a/17578272
UIViewController* CLBGetTopMostViewController(UIViewController* vc) {
    if([vc isKindOfClass:[UINavigationController class]]){
        UINavigationController* navController = (UINavigationController*)vc;

        if(nil != navController.visibleViewController){
            return CLBGetTopMostViewController(navController.visibleViewController);
        }else{
            return navController;
        }
    }else if([vc isKindOfClass:[UITabBarController class]]){
        UITabBarController* tabController = (UITabBarController*)vc;

        if(nil != tabController.presentedViewController){
            return CLBGetTopMostViewController(tabController.presentedViewController);
        }else if(nil != tabController.selectedViewController){
            return CLBGetTopMostViewController(tabController.selectedViewController);
        }else{
            return tabController;
        }
    }else if(nil != vc.presentedViewController){
        return CLBGetTopMostViewController(vc.presentedViewController);
    }else{
        return vc;
    }
}

UIViewController* CLBGetTopMostViewControllerOfRootWindow() {
    return CLBGetTopMostViewController([UIApplication sharedApplication].delegate.window.rootViewController);
}

static void ensureFormatterExists() {
    if(!isoDateFormatter){
        isoDateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [isoDateFormatter setLocale:enUSPOSIXLocale];
        [isoDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
        [isoDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    }
}

NSString* CLBISOStringFromDate(NSDate* date) {
    ensureFormatterExists();

    return [isoDateFormatter stringFromDate:date];
}

NSDate* CLBDateFromISOString(NSString* dateString) {
    ensureFormatterExists();

    return [isoDateFormatter dateFromString:dateString];
}

BOOL CLBIsSimulator() {
    if(floor(NSFoundationVersionNumber) >= 1200.0 /* NSFoundationVersionNumber_iOS_9_0 not implemented */) {
        return [NSProcessInfo processInfo].environment[@"SIMULATOR_DEVICE_NAME"] != nil;
    }else{
        return ([[[[UIDevice currentDevice] model] description] rangeOfString:@"Simulator" options:NSCaseInsensitiveSearch].location != NSNotFound);
    }
}

UIImage* CLBFancyCharacterAsImageWithColor(NSString* character, CGFloat fontSize, UIColor* fontColor) {
    UILabel* tempLabel = [[UILabel alloc] init];
    tempLabel.backgroundColor = [UIColor clearColor];
    tempLabel.textColor = fontColor;
    UIFont* iconFont = [UIFont fontWithName:@"ios7-icon" size:fontSize];

    // no icon if the font can't be loaded
    if(iconFont == nil){
        return nil;
    }

    tempLabel.font = iconFont;
    tempLabel.text = character;
    [tempLabel sizeToFit];

    UIGraphicsBeginImageContextWithOptions([tempLabel bounds].size, NO, 0);
    [[tempLabel layer] renderInContext: UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

UIColor* CLBColorFromHex(long hex) {
    return [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:1.0];
}

UIColor* CLBDefaultAccentColor() {
    return [UIColor colorWithRed:0 green:0.49 blue:1 alpha:1];
}

UIColor* CLBDefaultUserMessageTextColor(void) {
    return [UIColor whiteColor];
}

UIColor* CLBRedColor() {
    return CLBColorFromHex(0xff2851);
}

UIColor* CLBExtraLightGrayColor(BOOL supportDarkMode) {
    if (@available(iOS 11.0, *)) {
        if (supportDarkMode) {
            return [UIColor colorNamed:@"CLBExtraLightGray" inBundle:[ClarabridgeChat getResourceBundle] compatibleWithTraitCollection:nil];
        }
    }
    
    return CLBColorFromHex(0xededed);
}

UIColor* CLBLightGrayColor() {
    return CLBColorFromHex(0xcbcbcb);
}

UIColor* CLBMediumGrayColor() {
    return CLBColorFromHex(0xb2b2b2);
}

UIColor* CLBDarkGrayColor(BOOL supportDarkMode) {
    if (@available(iOS 11.0, *)) {
        if (supportDarkMode) {
            return [UIColor colorNamed:@"CLBDarkGray" inBundle:[ClarabridgeChat getResourceBundle] compatibleWithTraitCollection:nil];
        }
    }
    
    return CLBColorFromHex(0x919191);
}

UIColor* CLBExtraDarkGrayColor(BOOL supportDarkMode) {
    if (@available(iOS 11.0, *)) {
        if (supportDarkMode) {
            return [UIColor colorNamed:@"CLBExtraDarkGray" inBundle:[ClarabridgeChat getResourceBundle] compatibleWithTraitCollection:nil];
        }
    }
    
    return CLBColorFromHex(0x222222);
}

UIColor* CLBSaturatedColorForColor(UIColor *color) {
    return [color colorWithAlphaComponent: .1f];
}

UIColor* CLBSystemBackgroundColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemBackgroundColor];
    }
    
    return [UIColor whiteColor];
}

UIColor* CLBNavBarItemTextColor(void) {
    if (@available(iOS 11.0, *)) {
        return [UIColor colorNamed:@"CLBNavBarItemText" inBundle:[ClarabridgeChat getResourceBundle] compatibleWithTraitCollection:nil];
    }
    
    return [UIColor blackColor];
}

UIColor* CLBLabelColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor labelColor];
    }

    return [UIColor blackColor];
}

UIColor* CLBSecondaryLabelColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondaryLabelColor];
    }

    return CLBColorFromHex(0x3c3c43);
}

UIColor* CLBWebviewBackgroundColor(void) {
    if (@available(iOS 11.0, *)) {
        return [UIColor colorNamed:@"CLBWebviewBackground" inBundle:[ClarabridgeChat getResourceBundle] compatibleWithTraitCollection:nil];
    }
    
    return [[UIColor blackColor] colorWithAlphaComponent:0.7];
}

UIBlurEffectStyle CLBBlurEffectStyle(void) {
    if (@available(iOS 10.0, *)) {
        return UIBlurEffectStyleProminent;
    }
    
    return UIBlurEffectStyleExtraLight;
}

NSString* CLBEncodeSessionToken(NSString *userId, NSString *sessionToken) {
    NSString *headerValue = [NSString stringWithFormat:@"%@:%@", userId, sessionToken];
    NSData *headerValueData = [headerValue dataUsingEncoding:NSUTF8StringEncoding];

    return [headerValueData base64EncodedStringWithOptions:kNilOptions];
}

CGRect CLBSafeBoundsForView(UIView *view) {
    if (@available(iOS 11.0, *)) {
        CGFloat safeX = view.safeAreaInsets.left;
        CGFloat safeY = view.safeAreaInsets.top;
        CGFloat safeWidth = view.bounds.size.width - (view.safeAreaInsets.left + view.safeAreaInsets.right);
        CGFloat safeHeight = view.bounds.size.height - (view.safeAreaInsets.top + view.safeAreaInsets.bottom);
        
        return CGRectMake(safeX, safeY, safeWidth, safeHeight);
    } else {
        return view.bounds;
    }
}

UIEdgeInsets CLBSafeAreaInsetsForView(UIView *view) {
    if (@available(iOS 11.0, *)) {
        return view.safeAreaInsets;
    } else {
        return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    }
}

long long CLBSizeForFile(NSURL *url) {
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:nil];
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    long long fileSize = [fileSizeNumber longLongValue];
    
    return fileSize;
}

NSString *CLBContentTypeForPathExtension(NSString *extension) {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
}

NSString *CLBFilenameForURL(NSString *url) {
    if (url == nil) {
        return @"";
    }
    
    NSRange lastPathComponentIndex = [url rangeOfString:@"/" options:NSBackwardsSearch];
    
    if (lastPathComponentIndex.location == NSNotFound) {
        return @"";
    }
    
    NSString *lastPathComponent = [url substringFromIndex:lastPathComponentIndex.location + 1];
    return [lastPathComponent stringByRemovingPercentEncoding] ?: lastPathComponent;
}

void CLBOpenExternalURL(NSURL* url) {
    if (CLBIsIOS10OrLater()) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }else{
        [[UIApplication sharedApplication] openURL:url];
    }
}

id CLBSanitizeNSNull(id value) {
    if (value == [NSNull null]){
        return nil;
    }
    
    return value;
}

UIActivityIndicatorViewStyle CLBActivityIndicatorViewStyleWhite() {
    if (@available(iOS 13.0, *)) {
        return UIActivityIndicatorViewStyleMedium;
    }
    
    return UIActivityIndicatorViewStyleWhite;
}

UIActivityIndicatorViewStyle CLBActivityIndicatorViewStyleGray() {
    if (@available(iOS 13.0, *)) {
        return UIActivityIndicatorViewStyleMedium;
    }
    
    return UIActivityIndicatorViewStyleGray;
}

#pragma mark - Dark Mode

UIColor* CLBConversationAccentColor() {
    CLBSettings* settings = [ClarabridgeChat settings];
    
    if (@available(iOS 13.0, *)) {
        return [[UIColor alloc]initWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return settings.conversationAccentColorDarkMode ? settings.conversationAccentColorDarkMode : UIColor.systemBlueColor;
            } else {
                return settings.conversationAccentColor ? settings.conversationAccentColor : UIColor.systemBlueColor;
            }
        }];
    }
    
    return settings.conversationAccentColor ? settings.conversationAccentColor : UIColor.systemBlueColor;
}

UIColor* CLBUserMessageTextColor() {
    CLBSettings* settings = [ClarabridgeChat settings];
    
    if (@available(iOS 13.0, *)) {
        return [[UIColor alloc]initWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return settings.userMessageTextColorDarkMode ? settings.userMessageTextColorDarkMode : CLBDefaultUserMessageTextColor();
            } else {
                return settings.userMessageTextColor ? settings.userMessageTextColor : CLBDefaultUserMessageTextColor();
            }
        }];
    }
    
    return settings.userMessageTextColor ? settings.userMessageTextColor : CLBDefaultUserMessageTextColor();
}

UIStatusBarStyle CLBConversationStatusBarStyle() {
    CLBSettings* settings = [ClarabridgeChat settings];
    if (@available(iOS 13.0, *)) {
        
        switch(UITraitCollection.currentTraitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleDark :
            return settings.conversationStatusBarStyleDarkMode ? settings.conversationStatusBarStyleDarkMode : UIStatusBarStyleDefault;
                break;
            default :
                return settings.conversationStatusBarStyle ? settings.conversationStatusBarStyle : UIStatusBarStyleDefault;
        }
    }
    
    return settings.conversationStatusBarStyle ? settings.conversationStatusBarStyle : UIStatusBarStyleDefault;
}


