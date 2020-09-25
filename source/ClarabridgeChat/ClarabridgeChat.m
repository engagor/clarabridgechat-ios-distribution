//
//  ClarabridgeChat.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "ClarabridgeChat.h"
#import "ClarabridgeChat+Private.h"
#import <CoreText/CoreText.h>
#import "CLBUtility.h"
#import "CLBRemoteObjectSynchronizer.h"
#import "CLBAppDelegate.h"
#import "CLBAppDelegateProxy.h"
#import "CLBConfig.h"
#import "CLBRemotePushToken.h"
#import "CLBPushNotificationFilter.h"
#import "CLBConfigFetchScheduler.h"
#import "CLBRemoteResponse.h"
#import "CLBAvatarImageLoaderStrategy.h"
#import "CLBUserSynchronizer.h"
#import "CLBDependencyManager.h"
#import "CLBUser+Private.h"
#import "CLBConversation+Private.h"
#import "CLBConversationViewController.h"
#import "CLBApiClient.h"
#import "CLBMessage+Private.h"
#import "CLBUserLifecycleManager.h"
#import "CLBConversationMonitor.h"
#import "CLBAFNetworkReachabilityManager.h"
#import "CLBMessageAction+Private.h"
#import <UserNotifications/UserNotifications.h>
#import "CLBLocalization.h"
#import "CLBSettings+Private.h"
#import "CLBAuthorInfo.h"
#import "CLBConversationStorage.h"
#import "CLBConversation+Private.h"
#import "CLBDependencyManager+Private.h"
#import "CLBConversationStorageManager.h"
#import "CLBConversationController.h"
#import "CLBConversationListViewController.h"
#import "NSError+ClarabridgeChat.h"

NSString *const CLBInitializationDidCompleteNotification = @"CLBInitializationDidCompleteNotification";
NSString *const CLBInitializationDidFailNotification = @"CLBInitializationDidFailNotification";
NSString *const CLBLoginDidCompleteNotification = @"CLBLoginDidCompleteNotification";
NSString *const CLBLoginDidFailNotification = @"CLBLoginDidFailNotification";
NSString *const CLBLogoutDidCompleteNotification = @"CLBLogoutDidCompleteNotification";
NSString *const CLBLogoutDidFailNotification = @"CLBLogoutDidFailNotification";
NSString *const CLBReachabilityStatusChangedNotification = @"CLBReachabilityStatusChangedNotification";
NSString *const CLBPushNotificationIdentifier = @"SmoochNotification";
NSString *const CLBUserIdentifier = @"CLBUserIdentifier";
NSString *const CLBConversationIdentifier = @"CLBConversationIdentifier";
NSString *const CLBErrorCodeIdentifier = @"CLBErrorCodeIdentifier";
NSString *const CLBErrorDescriptionIdentifier = @"CLBErrorDescriptionIdentifier";
NSString *const CLBErrorDomainIdentifier = @"CLBErrorDomainIdentifier";
NSString *const CLBStatusCodeIdentifier = @"CLBStatusCodeIdentifier";
NSString *const CLBUserNotificationReplyActionIdentifier = @"CLBPushNotificationReplyActionIdentifier";
NSString *const CLBUserNotificationReplyCategoryIdentifier = @"SmoochReplyableNotification";
NSString *const CLBIntentConversationStart = @"conversation:start";

@interface ClarabridgeChat ()
+ (void)setupDependencyManager;
@end

static BOOL didBecomeActiveOnce;
static BOOL didGoToBackground;
static BOOL suppressInAppNotifs;
static BOOL isPresenting;
static BOOL launchedFromPushNotification;
static CLBAppDelegate *clbAppDelegate;
static CLBImageLoader *avatarImageLoader;

static CLBDependencyManager *depManager;
static CLBUserLifecycleManager *userLifecycleManager;
static CLBAFNetworkReachabilityManager *reachabilityManager;

static NSString *userFirstName;
static NSString *userLastName;

__weak static id<CLBConversationDelegate> conversationDelegate;
__weak static id<CLBConversationListDelegate> conversationListDelegate;

static void(^initCompletionHandler)(NSError *, NSDictionary *);

static void(^configFetchSchedulerCompletionHandler)(NSError *, NSDictionary *) = ^(NSError *error, NSDictionary *userInfo) {
    if (!error) {
        CLBEnsureMainThread(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:CLBInitializationDidCompleteNotification object:nil userInfo:nil];
        });
    } else {
        CLBEnsureMainThread(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:CLBInitializationDidFailNotification object:nil userInfo:userInfo];
        });
    }

    if (initCompletionHandler) {
        CLBEnsureMainThread(^{
            initCompletionHandler(error, userInfo);
        });
    }
};

__weak static CLBConversationViewController *conversationVC;
__weak static CLBConversationListViewController *conversationListVC;

@implementation ClarabridgeChat

+ (void)initWithSettingsInternal:(CLBSettings *)settings {
    if(!depManager) {
        depManager = [[CLBDependencyManager alloc] initWithSettings:settings];
        [CLBUser setCurrentUser:depManager.user];
        [depManager.configFetchScheduler addCallbackOnInitializationComplete:^ {
            CLBEnsureMainThread(^{
                [self setupDependencyManager];
            });
        }];

        userLifecycleManager = [[CLBUserLifecycleManager alloc] initWithDependencyManager:depManager];
    }

    [self fetchConfig];
}

+ (NSString *)getLegacyIdentifier {
    return CLBGetLegacyUniqueDeviceIdentifier();
}

+ (void)setupDependencyManager {
    CLBSettings *settings = depManager.sdkSettings;
    [depManager createObjectsWithSettings:settings];
    depManager.conversation.delegate = conversationDelegate;
    [depManager handleUpdatedSettings];



    [CLBUser currentUser].firstName = userFirstName;
    [CLBUser currentUser].lastName = userLastName;

    id<CLBImageLoaderStrategy> strategy = [[CLBAvatarImageLoaderStrategy alloc] init];
    avatarImageLoader = [[CLBImageLoader alloc] initWithStrategy:strategy];

    [[CLBAFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(CLBAFNetworkReachabilityStatus status) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBReachabilityStatusChangedNotification object:[CLBAFNetworkReachabilityManager sharedManager]];
    }];
    [[CLBAFNetworkReachabilityManager sharedManager] startMonitoring];

    if(settings.enableAppDelegateSwizzling){
        [CLBAppDelegateProxy proxyAppDelegateMethods];
    }

    CLBPushNotificationFilter *pushFilter = [CLBPushNotificationFilter new];
    clbAppDelegate = [[CLBAppDelegate alloc] initWithPushFilter:pushFilter dependencyManager:depManager];

    if(CLBIsIOS10OrLater() && settings.enableUserNotificationCenterDelegateOverride){
        clbAppDelegate.otherNotificationCenterDelegate = [UNUserNotificationCenter currentNotificationCenter].delegate;
        [UNUserNotificationCenter currentNotificationCenter].delegate = clbAppDelegate;
    }
}

+ (CLBConversation *)conversation {
    return depManager.conversation;
}

+ (void)conversationById:(NSString *)conversationId completionHandler:(nullable void (^)(NSError * _Nullable, CLBConversation * _nullable))handler {
    if (depManager.conversationStorageManager == nil || depManager.conversationController == nil) {
        return;
    }

    if (conversationId == nil || conversationId.length == 0) {
        NSLog(@"<CLARABRIDGECHAT::WARNING> Get Conversation by ID called with null or empty conversation ID. Ignoring!");
        return;
    }

    if ([depManager.conversationStorageManager messagesAreInSyncInStorageForConversationId:conversationId]) {
        CLBEnsureMainThread(^{
            handler(nil, [depManager readConversation:conversationId]);
        });
    } else {
        [depManager.conversationController getConversationById:conversationId withCompletionHandler:^(NSError *error, CLBConversation *conversation) {
            CLBEnsureMainThread(^{
                handler(error, depManager.conversation);
            });
        }];
    }
}

+ (CLBDependencyManager*)dependencyManager {
    return depManager;
}

+ (void)setDependencyManager:(CLBDependencyManager *)newManager {
    depManager = newManager;
}

+ (void)setUserLifecycleManager:(CLBUserLifecycleManager*)newManager {
    userLifecycleManager = newManager;
}

+ (CLBUserLifecycleManager*)getUserLifecycleManager {
    return userLifecycleManager;
}

+ (void)setImageLoader:(CLBImageLoader *)imageLoader {
    avatarImageLoader = imageLoader;
}

+ (void)setDidBecomeActiveOnce:(BOOL)didBecomeActive {
    didBecomeActiveOnce = didBecomeActive;
}

+ (void)failWithError:(NSString*)errorMessage level:(NSString*)level completionHandler:(nullable void (^)(NSError  *_Nullable, NSDictionary  *_Nullable))handler {
    NSLog(@"<CLARABRIDGECHAT::%@> %@", level, errorMessage);
    
    if (handler) {
        NSError *error = [NSError errorWithDomain:CLBErrorDomainIdentifier code:400 userInfo:nil];
        
        NSDictionary *userInfo = @{
                                   CLBErrorCodeIdentifier: @"bad_request",
                                   CLBStatusCodeIdentifier: @400,
                                   CLBErrorDescriptionIdentifier: errorMessage
                                   };
        
        handler(error, userInfo);
    }
}

+ (void)failWithError:(NSString*)errorMessage completionHandler:(nullable void (^)(NSError  *_Nullable, NSDictionary  *_Nullable))handler {
    [self failWithError:errorMessage level:@"WARNING" completionHandler:handler];
}

+ (void)login:(NSString *)externalId jwt:(NSString *)jwt completionHandler:(nullable void (^)(NSError  *_Nullable, NSDictionary  *_Nullable))handler {
    CLBSettings *currentSettings = depManager.sdkSettings;

    BOOL sameUser = [externalId isEqualToString:currentSettings.externalId];
    BOOL sameJWT = jwt == currentSettings.jwt || [jwt isEqualToString:currentSettings.jwt];

    if(externalId.length == 0){
        [self failWithError:@"Login called with nil or empty externalId. Call logout instead!" completionHandler:handler];
    } else if (!jwt || jwt.length == 0) {
        [self failWithError:@"Login called with nil or empty jwt. Ignoring!" completionHandler:handler];
    }else if(!currentSettings){
        [self failWithError:@"Login called before settings have been initialized. Ignoring!" completionHandler:handler];
    }else if([self isConversationShown] && !sameUser){
        [self failWithError:@"Tried to switch users while on the conversation screen. Ignoring!" completionHandler:handler];
    }else if([self isConversationListShown] && !sameUser){
        [self failWithError:@"Tried to switch users while on the conversation list screen. Ignoring!" completionHandler:handler];
    }else if(sameUser && sameJWT){
        if (depManager.userSynchronizer.lastLoginResult == CLBLastLoginResultSuccess) {
            if (handler) {
                CLBEnsureMainThread(^{
                    handler(nil, @{
                        CLBUserIdentifier: [CLBUser currentUser]
                    });
                });
            }
        } else {
            [self failWithError:[NSString stringWithFormat:@"User %@ is already logged in. Ignoring!", externalId] completionHandler:handler];
        }
    }else{
        void (^login)(void) = ^{
            if(!userLifecycleManager.isLoggedIn){
                // Upgrading an anonymous user. The conversation will be merged
                [depManager.conversation removeFromDisk];
            }
            
            [userLifecycleManager login:externalId jwt:jwt completionHandler:^(NSError *error, NSDictionary *userInfo) {
                if (handler) {
                    handler(error, userInfo);
                }
            }];
        };
        
        if (depManager.configFetchScheduler.isInitializationComplete) {
            login();
        } else {
            [depManager.configFetchScheduler addCallbackOnInitializationComplete:^ {
                login();
            }];
        }
    }
}

+ (void)logoutWithCompletionHandler:(void (^)(NSError  *_Nullable, NSDictionary  *_Nullable))completionHandler {
    if(!depManager.sdkSettings){
        [self failWithError:@"Logout called before settings have been initialized. Ignoring!" completionHandler:completionHandler];
    }else if([self isConversationShown]){
        [self failWithError:@"Tried to switch users while on the conversation screen. Ignoring!" completionHandler:completionHandler];
    }else if([self isConversationListShown]){
        [self failWithError:@"Tried to switch users while on the conversation list screen. Ignoring!" completionHandler:completionHandler];
    }else if(!userLifecycleManager.isLoggedIn){
        [self failWithError:@"Logout called, but no user was logged in. Ignoring!" level:@"INFO" completionHandler:completionHandler];
    }else{
        void (^logout)(void) = ^{
            [userLifecycleManager logoutWithCompletionHandler:^(NSError *error, NSDictionary *userInfo) {
                if (completionHandler) {
                    completionHandler(error, userInfo);
                }
            }];
        };
        
        if (depManager.configFetchScheduler.isInitializationComplete) {
            logout();
        } else {
            [depManager.configFetchScheduler addCallbackOnInitializationComplete:^{
                logout();
            }];
        }
    }
}

+ (BOOL)isUserLoggedIn {
    return [userLifecycleManager isLoggedIn];
}

+ (void)destroy {
    if (!depManager) {
        NSLog(@"<CLARABRIDGECHAT::WARNING> Tried to destroy without being initialized first. Ignoring!");
        return;
    }

    if ([self isConversationShown]) {
        NSLog(@"<CLARABRIDGECHAT::WARNING> Tried to destroy while on the conversation screen. Ignoring!");
        return;
    }

    if ([self isConversationListShown]) {
        NSLog(@"<CLARABRIDGECHAT::WARNING> Tried to destroy while on the conversation list screen. Ignoring!");
        return;
    }

    [userLifecycleManager destroy];
    [CLBUser setCurrentUser:nil];

    if(CLBIsIOS10OrLater() && self.settings.enableUserNotificationCenterDelegateOverride){
        [UNUserNotificationCenter currentNotificationCenter].delegate = clbAppDelegate.otherNotificationCenterDelegate;
    }

    [[CLBAFNetworkReachabilityManager sharedManager] stopMonitoring];

    userLifecycleManager = nil;
    depManager = nil;
    avatarImageLoader = nil;
}

+ (CLBImageLoader*)avatarImageLoader {
    return avatarImageLoader;
}

+ (void)initWithSettings:(CLBSettings *)settings completionHandler:(nullable void (^)(NSError  *_Nullable, NSDictionary  *_Nullable))handler {
    if(settings == nil) {
        [self failWithError:@"Init called with nil settings, aborting init sequence!" level:@"ERROR" completionHandler:handler];
    } else if(depManager.sdkSettings) {
        [self failWithError:@"Init called more than once, aborting init sequence!" level:@"ERROR" completionHandler:handler];
    } else if(!settings.integrationId || [@"" isEqualToString:[settings.integrationId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]){
            [self failWithError:@"Provided settings did not have an integration id, aborting init sequence!" level:@"ERROR" completionHandler:handler];
    } else {
        initCompletionHandler = handler;
        [self initWithSettingsInternal:settings];
    }
}

+ (CLBSettings *)settings {
    return depManager.sdkSettings;
}

+ (BOOL)isPreparedToShow {
    if(!depManager.sdkSettings) {
        NSLog(@"<CLARABRIDGECHAT::ERROR> Show called before settings have been initialized!");
        return NO;
    }

    return YES;
}

+ (UIViewController *)newConversationViewController {
    return [[self class] newConversationViewControllerWithStartingText:nil];
}

+(void)newConversationViewControllerWithId:(NSString *)conversationId completionHandler:(nullable void(^)(NSError * _Nullable error, UIViewController * _Nullable viewController))handler {
    [self newConversationViewControllerWithId:conversationId startingText:nil completionHandler:handler];
}

+ (UIViewController *)newConversationViewControllerWithStartingText:(NSString *)startingText {
    if(!depManager.sdkSettings){
        NSLog(@"<CLARABRIDGECHAT::ERROR> newConversationViewController called before settings have been initialized!");
        return nil;
    }
    CLBConversationViewController *viewController = [depManager startConversationViewControllerWithStartingText:startingText];
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    conversationVC = viewController;
    return viewController;
}

+(void)newConversationViewControllerWithId:(NSString *)conversationId startingText:(nullable NSString *)startingText completionHandler:(nullable void(^)(NSError * _Nullable error, UIViewController * _Nullable viewController))handler {

    [self loadConversation:conversationId completionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {

        if (!error) {
            if(!depManager.sdkSettings){
                NSLog(@"<CLARABRIDGECHAT::ERROR> newConversationViewController called before settings have been initialized!");
                return;
            }
            CLBConversationViewController *viewController = [depManager startConversationViewControllerWithStartingText:startingText];
            viewController.modalPresentationStyle = UIModalPresentationFullScreen;
            conversationVC = viewController;

            handler(nil, viewController);
        } else {
            handler(error, nil);
        }
    }];
}

+ (void)show {
    [self showWithStartingText:nil];
}

+(void)showConversationWithId:(NSString *)conversationId {
    [self showConversationWithId:conversationId andStartingText:nil];
}

+ (void)showWithStartingText:(NSString *)startingText {
    if ([self isPreparedToShow] && !isPresenting) {
        [self showConversationFromViewController:CLBGetTopMostViewControllerOfRootWindow() withStartingText:startingText];
    }
}

+(void)showConversationWithId:(NSString *)conversationId andStartingText:(nullable NSString *)startingText {
    if ([self isPreparedToShow] && !isPresenting) {
        [self loadConversation:conversationId completionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
                if (error) {
                    NSLog(@"<CLARABRIDGECHAT::ERROR> load conversation failed with the specified ID!");
                } else {
                    [self showWithStartingText:startingText];
                }
        }];
    }
}

+ (void)close {
    if(!depManager.sdkSettings){
        NSLog(@"<CLARABRIDGECHAT::ERROR> Close called before settings have been initialized!");
        return;
    }

    if(conversationVC != nil){
        [conversationVC.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

+ (void)showConversation:(NSString*)conversationId {
    [self loadConversation:conversationId completionHandler:^(NSError  *_Nullable error, NSDictionary  *_Nullable userInfo) {
        if (!error) {
            [self showConversationWithConversationId:conversationId];
        }
    }];
}

+ (void)showConversationWithConversationId:(NSString *)conversationId {
    [self showConversationFromViewController:CLBGetTopMostViewControllerOfRootWindow()];
}

+ (void)showConversationFromViewController:(UIViewController *)viewController {
    [self showConversationFromViewController:viewController withStartingText:nil];
}

+(void)showConversationWithId:(NSString *)conversationId fromViewController:(UIViewController*)viewController {
    [self showConversationWithId:conversationId fromViewController:viewController andStartingText:nil];
}

+ (void)showConversationFromViewController:(UIViewController *)viewController withStartingText:(NSString *)startingText {
     if([self shouldShowConversationFromViewController]) {
         [self createAndPresentConversation:viewController withStartingText:startingText];
     }
}

+(void)showConversationWithId:(NSString *)conversationId fromViewController:(UIViewController*)viewController andStartingText:(nullable NSString *)startingText {

    if([self shouldShowConversationFromViewController]) {
        [self loadConversation:conversationId completionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
                if (error) {
                    NSLog(@"<CLARABRIDGECHAT::ERROR> load conversation failed with the specified ID!");
                } else {
                    [self showConversationFromViewController:viewController withStartingText:startingText];
                }
        }];
    }
}

+(BOOL)shouldShowConversationFromViewController {
    return ![self isConversationShown] && [self isPreparedToShow] && !isPresenting;
}

+ (void)createAndPresentConversation:(UIViewController*)presentingViewController withStartingText:(NSString *)startingText {
    CLBConversationViewController *newConversationViewController = [depManager startConversationViewControllerWithStartingText:startingText];
    conversationVC = newConversationViewController;
    isPresenting = YES;
    suppressInAppNotifs = YES;
    [presentingViewController presentViewController:newConversationViewController animated:YES completion:^{
        suppressInAppNotifs = NO;
        isPresenting = NO;
    }];
}

+ (void)setConversationInputDisplayed:(BOOL)displayed {
    [CLBSOMessagingViewController setInputDisplayed:displayed];
}

#pragma mark - Conversation List

+ (void)showConversationList {
    [self showConversationListFromViewController:CLBGetTopMostViewControllerOfRootWindow()];
}

+(void)showConversationListWithoutCreateConversationButton {
    [ClarabridgeChat showConversationListFromViewControllerWithoutCreateConversationButton:CLBGetTopMostViewControllerOfRootWindow()];
}

+ (void)closeConversationList {
    if(!depManager.sdkSettings){
        NSLog(@"<CLARABRIDGECHAT::ERROR> Close called before settings have been initialized!");
        return;
    }
    if(conversationListVC != nil){
        [conversationListVC.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

+ (void)showConversationListFromViewController:(UIViewController *)viewController {
    [self createAndPresentConversationListWithCreateConversationButton:YES from:viewController];
}

+(void)showConversationListFromViewControllerWithoutCreateConversationButton:(UIViewController *)viewController {
    [self createAndPresentConversationListWithCreateConversationButton:NO from:viewController];
}

+ (void)createAndPresentConversationListWithCreateConversationButton:(BOOL)showCreateConversationButton from:(UIViewController*)presentingViewController {
    if(![self shouldShowConversationList]){
        return;
    }

    CLBConversationListViewController *newConversationListViewController = [depManager startConversationListViewControllerWithCreateConversationButton:showCreateConversationButton];
    conversationListVC = newConversationListViewController;
    conversationListVC.delegate = conversationListDelegate;

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:newConversationListViewController];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    isPresenting = YES;
    suppressInAppNotifs = YES;
    [presentingViewController presentViewController:navigationController animated:YES completion:^{
        suppressInAppNotifs = NO;
        isPresenting = NO;
    }];
}

+ (BOOL)shouldShowConversationList {
    return ![self isConversationListShown] && ![self isConversationShown] && [self isPreparedToShow] && !isPresenting;
}

+ (BOOL)isConversationListShown {
    return [CLBConversationListViewController isConversationListShown];
}

+ (UIViewController *)newConversationListViewController {
    return [ClarabridgeChat newConversationListViewControllerWithCreateConversationButton:YES];
}

+(nullable UIViewController *)newConversationListViewControllerWithoutCreateConversationButton {
    return [ClarabridgeChat newConversationListViewControllerWithCreateConversationButton:NO];
}

+ (UIViewController *)newConversationListViewControllerWithCreateConversationButton:(BOOL)showCreateConversationButton {
    if(!depManager.sdkSettings) {
        NSLog(@"<CLARABRIDGECHAT::ERROR> newConversationListViewController called before settings have been initialized!");
        return nil;
    }
    CLBConversationListViewController *viewController = [depManager startConversationListViewControllerWithCreateConversationButton:showCreateConversationButton];
    conversationListVC = viewController;
    conversationListVC.delegate = conversationListDelegate;
    return viewController;
}

+(void)setConversationListDelegate:(nullable id<CLBConversationListDelegate>)delegate {
    conversationListDelegate = delegate;
    conversationListVC.delegate = delegate;
}

+ (NSBundle *)getResourceBundle {
    static NSBundle *resourceBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString *mainBundlePath = [[NSBundle mainBundle] resourcePath];
        NSString *bundlePath = [mainBundlePath stringByAppendingPathComponent:@"ClarabridgeChat.bundle"];
        resourceBundle = [NSBundle bundleWithPath:bundlePath];

        if(!resourceBundle){
            resourceBundle = [NSBundle bundleForClass:self];
        }
    });
    return resourceBundle;
}

+ (UIImage*)getImageFromResourceBundle:(NSString*)imageName {
    return [UIImage imageWithContentsOfFile:[[self getResourceBundle] pathForResource:imageName ofType:@"png"]];
}

+ (BOOL)isConversationShown {
    return [CLBConversationViewController isConversationShown];
}

// Dynamically load the font instead of declaring it in app's info.plist
// http://www.marco.org/2012/12/21/ios-dynamic-font-loading
+ (void)loadSymbolFont {
    NSString *fontPath = [[self getResourceBundle] pathForResource:@"ios7-icon" ofType:@"ttf"];

    if(fontPath == nil){
        NSLog(@"<CLARABRIDGECHAT::ERROR> Could not find \"ClarabridgeChat.bundle\" resource bundle. Please include it in your project's \"Copy Bundle Resources\" build phase");
        return;
    }

    // Fix deadlock. See http://lists.apple.com/archives/cocoa-dev/2010/Sep/msg00451.html and http://stackoverflow.com/questions/24900979/cgfontcreatewithdataprovider-hangs-in-airplane-mode
    [UIFont familyNames];

    NSData *inData = [NSData dataWithContentsOfFile:fontPath];
    CFErrorRef error;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)inData);
    CGFontRef font = CGFontCreateWithDataProvider(provider);

    CTFontManagerRegisterGraphicsFont(font, &error);

    CFRelease(font);
    CFRelease(provider);
}

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidFinishLaunching:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

+ (void)applicationDidFinishLaunching:(NSNotification*)notification {
    [self loadSymbolFont];

    CLBPushNotificationFilter *pushFilter = clbAppDelegate.pushFilter ?: [CLBPushNotificationFilter new];

    NSDictionary *pushNotificationInfo = (notification.userInfo)[UIApplicationLaunchOptionsRemoteNotificationKey];
    BOOL hasPushNotification = pushNotificationInfo != nil;
    BOOL isClarabridgeChatPushNotification = [pushFilter isClarabridgeChatNotification:pushNotificationInfo];

    if(hasPushNotification && isClarabridgeChatPushNotification){
        launchedFromPushNotification = YES;
    }
}

+ (id<UIApplicationDelegate>)clbAppDelegate {
    return clbAppDelegate;
}

+ (BOOL)wasLaunchedFromPushNotification {
    return launchedFromPushNotification;
}

+ (void)applicationDidBecomeActive:(NSNotification*)notification {
    if(!didBecomeActiveOnce && depManager.sdkSettings) {
        [self fetchConfig];
    }

    didBecomeActiveOnce = YES;

    if(launchedFromPushNotification){
        [self showConversation:depManager.conversation withAction:CLBActionPushNotificationTapped info:notification.userInfo];
    }

    if(!didGoToBackground){
        // Application is waking from inactive state, not background. No need to reconnect schedulers
        return;
    }

    didGoToBackground = NO;

    if (depManager.configFetchScheduler.config.validityStatus == CLBAppStatusUnknown && depManager.sdkSettings.appId) {
        [depManager.configFetchScheduler restore];
        [self fetchConfig];
    } else if (depManager.configFetchScheduler.config.validityStatus == CLBAppStatusValid) {
        if (depManager.userSynchronizer.user.settings.profileEnabled && !depManager.userSynchronizer.rescheduleAutomatically) {
            depManager.userSynchronizer.rescheduleAutomatically = YES;
            [depManager.userSynchronizer scheduleImmediately];
        }

        if([self conversationStarted] && depManager.userSynchronizer.user.settings.realtime.enabled) {
            if (depManager.conversationMonitor.didConnectOnce) {
                [depManager.conversationMonitor connectImmediately];
            } else {
                [depManager.conversationMonitor connect];
            }
        }
    }
}

+ (BOOL)conversationStarted {
    return depManager.userSynchronizer.user.conversationStarted || depManager.config.multiConvoEnabled;
}

+ (void)applicationDidEnterBackground:(NSNotification*)notification {
    if(depManager.configFetchScheduler.config.validityStatus == CLBAppStatusValid) {
        depManager.userSynchronizer.rescheduleAutomatically = NO;
        [depManager.userSynchronizer scheduleImmediately];

        [depManager.conversationMonitor disconnect];
    } else {
        [depManager.configFetchScheduler destroy];
    }

    didGoToBackground = true;
}

+ (void)showConversationWithAction:(CLBAction)action info:(NSDictionary *)info {
    if (info[@"conversationId"] && ![info[@"conversationId"] isEqualToString:depManager.conversation.conversationId]) {
        [self conversationById:info[@"conversationId"] completionHandler:^(NSError * _Nullable error, CLBConversation * _Nullable conversation) {
            if (conversation) {
                [self showConversation:conversation withAction:action info:info];
            }
        }];
    } else {
        [self showConversation:depManager.conversation withAction:action info:info];
    }
}

+ (void)showConversation:(CLBConversation*)conversation withAction:(CLBAction)action info:(NSDictionary *)info {
    if (action == CLBActionPushNotificationTapped) {
        launchedFromPushNotification = NO;
    }

    // Use the global conversation object to get the delegate, temporary conversation instances will not have a delegate
    if ([depManager.conversation.delegate respondsToSelector:@selector(conversation:shouldShowForAction:withInfo:)]) {
        CLBEnsureMainThread(^{
            if ([depManager.conversation.delegate conversation:conversation shouldShowForAction:action withInfo:info]) {
                [self showConversation:conversation.conversationId];
            }
        });
    } else {
        [self showConversation:conversation.conversationId];
    }
}

+ (void)setUserFirstName:(NSString *)firstName lastName:(NSString *)lastName {
    userFirstName = firstName;
    userLastName = lastName;
}

+ (void)setPushToken:(NSData *)token {
    NSUInteger length = token.length;
    if (length == 0) {
        return;
    }
    
    const unsigned char *buffer = token.bytes;
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(length  *2)];
    for (int i = 0; i < length; ++i) {
        [hexString appendFormat:@"%02x", buffer[i]];
    }

    NSString *newToken = [hexString copy];
    NSString *savedDeviceToken = CLBGetPushNotificationDeviceToken();

    if (newToken && ![newToken isEqualToString:savedDeviceToken]) {
        CLBSetPushNotificationDeviceToken(newToken);

        BOOL userExists = depManager.userSynchronizer.user.userId != nil;

        if (userExists) {
            [self uploadPushToken:newToken];
        }
    }
}

+ (void)uploadPushToken:(NSString *)newToken {
    CLBRemotePushToken *pushToken = [[CLBRemotePushToken alloc] init];

    pushToken.appId = depManager.config.appId;
    pushToken.pushToken = newToken;
    pushToken.clientId = CLBGetUniqueDeviceIdentifier();
    pushToken.userId = depManager.userSynchronizer.user.userId;

    [depManager.synchronizer synchronize:pushToken completion:^(CLBRemoteResponse *response) {
        if(response.error){
            CLBSetPushNotificationDeviceToken(nil);
        }
        [depManager.configFetchScheduler logPushTokenIfExists];
    }];
}

+ (void)handlePushNotification:(NSDictionary *)userInfo {
    [clbAppDelegate handleNotification:userInfo];
}

+ (void)handleUserNotificationActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler {
    [clbAppDelegate handleUserNotificationActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:completionHandler];
}

+ (void)handleUserNotificationActionWithIdentifier:(NSString *)identifier withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler {
    [clbAppDelegate handleUserNotificationActionWithIdentifier:identifier withResponseInfo:responseInfo completionHandler:completionHandler];
}

+ (NSSet*)userNotificationCategories {
    NSString *title = [CLBLocalization localizedStringForKey:@"Reply"];

    if(CLBIsIOS10OrLater()){
        UNNotificationAction *action = [UNTextInputNotificationAction actionWithIdentifier:CLBUserNotificationReplyActionIdentifier
                                                                                     title:title
                                                                                   options:UNNotificationActionOptionAuthenticationRequired
                                                                      textInputButtonTitle:[CLBLocalization localizedStringForKey:@"Send"]
                                                                      textInputPlaceholder:[CLBLocalization localizedStringForKey:@"Type a message..."]];

        UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:CLBUserNotificationReplyCategoryIdentifier
                                                                                  actions:@[action]
                                                                        intentIdentifiers:@[]
                                                                                  options:UNNotificationCategoryOptionNone];

        return [NSSet setWithObject:category];
    }else if(CLBIsIOS9()) {
        UIMutableUserNotificationAction *textAction = [[UIMutableUserNotificationAction alloc] init];
        textAction.identifier = CLBUserNotificationReplyActionIdentifier;
        textAction.title = title;
        textAction.activationMode = UIUserNotificationActivationModeBackground;
        textAction.behavior = UIUserNotificationActionBehaviorTextInput;
        textAction.authenticationRequired = YES;

        UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
        category.identifier = CLBUserNotificationReplyCategoryIdentifier;
        [category setActions:@[textAction] forContext:UIUserNotificationActionContextDefault];
        [category setActions:@[textAction] forContext:UIUserNotificationActionContextMinimal];

        return [NSSet setWithObject:category];
    }else{
        return [NSSet set];
    }
}

+ (id<UNUserNotificationCenterDelegate>)userNotificationCenterDelegate {
    return clbAppDelegate;
}

+ (BOOL)didBecomeActiveOnce {
    return didBecomeActiveOnce;
}

+ (BOOL)shouldSuppressInAppNotifs {
    return suppressInAppNotifs;
}

+ (void)sendImage:(UIImage *)image withMetadata:(NSDictionary*)metadata withProgress:(void (^)(double progress))progressBlock completion:(void (^)(NSError *error, NSDictionary *responseObject))completionBlock {
    [[self class] sendMedia:nil image:image withMetadata:metadata withProgress:progressBlock completion:completionBlock];
}

+ (void)sendFile:(NSURL *)fileLocation withMetadata:(NSDictionary*)metadata withProgress:(void (^)(double progress))progressBlock completion:(void (^)(NSError *error, NSDictionary *responseObject))completionBlock {
    [[self class] sendMedia:fileLocation image:nil withMetadata:metadata withProgress:progressBlock completion:completionBlock];
}

+ (void)sendMedia:(NSURL *)fileLocation image:(UIImage *)image withMetadata:(NSDictionary*)metadata withProgress:(void (^)(double progress))progressBlock completion:(void (^)(NSError *error, NSDictionary *responseObject))completionBlock {
    [depManager.userSynchronizer scheduleImmediately];
    
    CLBApiClient *apiClient = depManager.synchronizer.apiClient;
    
    NSString* endpoint = [NSString stringWithFormat:@"/v2/apps/%@/conversations/%@/files", depManager.config.appId, depManager.conversation.conversationId];

    NSMutableDictionary *parameters = [[self class] authorPayload];
    
    if (metadata) {
        parameters[@"message"] = @{
                                   @"metadata": metadata
                                   };
    }
    
    if (image) {
        [apiClient uploadImage:image
                           url:endpoint
                    parameters:parameters
                      progress:progressBlock
                    completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                        CLBEnsureMainThread(^{
                            completionBlock(error, responseObject);
                        });
                    }];
    } else if (fileLocation) {
        [apiClient uploadFile:fileLocation
                          url:endpoint
                   parameters:parameters
                     progress:progressBlock
                   completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                       CLBEnsureMainThread(^{
                           completionBlock(error, responseObject);
                       });
                   }];
    }
}

+ (NSMutableDictionary *)authorPayload {
    return [NSMutableDictionary dictionaryWithDictionary:@{
                                                           @"author": [CLBAuthorInfo authorFieldForUser:depManager.userSynchronizer.user]
                                                           }];
}

+ (void)postback:(CLBMessageAction *)action toConversation:(CLBConversation *)conversation completion:(void (^)(NSError *error))completionBlock {
    if (depManager.configFetchScheduler.config.validityStatus != CLBAppStatusValid) {
        NSLog(@"<CLARABRIDGECHAT::WARNING> Postback called before initialization process has completed. Wait for CLBInitializationDidCompleteNotification before calling postback. Ignoring!");
        return;
    }

    CLBApiClient* apiClient = depManager.synchronizer.apiClient;
    NSString* endpoint = [NSString stringWithFormat:@"/v2/apps/%@/conversations/%@/postback", depManager.configFetchScheduler.config.appId, conversation.conversationId];
    NSMutableDictionary *parameters = [[self class] authorPayload];
    
    parameters[@"postback"] = @{
                                @"actionId" : action.actionId
                                };

    action.uiState = CLBMessageActionUIStateProcessing;
    [apiClient requestWithMethod:@"POST"
                             url:endpoint
                      parameters:parameters
                      completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                          action.uiState = nil;
                          if (completionBlock) {
                              completionBlock(error);
                          }
                      }];
}

+ (void)startConversationWithCompletionHandler:(void (^)(NSError *error, NSDictionary *userInfo))completionHandler {
    [self startConversationWithIntent:CLBIntentConversationStart completionHandler:completionHandler];
}

+ (void)startConversationWithIntent:(NSString*)intent completionHandler:(void (^)(NSError *error, NSDictionary *userInfo))completionHandler {
    [depManager.userSynchronizer startConversationOrCreateUserWithIntent:intent completionHandler:completionHandler];
}

+ (void)createConversationWithName:(nullable NSString *)displayName description:(nullable NSString *)description iconUrl:(nullable NSString *)iconUrl metadata:(nullable NSDictionary *)metadata message:(nullable NSArray<CLBMessage *> *)message completionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler {

    if (message && ![self messagesAreTextOnly:message]) {
        if (completionHandler) {

            CLBEnsureMainThread(^{
                completionHandler(NSError.createConversationMultipartMessageError, nil);
            });
        }

        return;
    }

    [depManager.userSynchronizer createConversationOrUserWithName:displayName description:description iconUrl:iconUrl metadata:metadata messages:message intent:CLBIntentConversationStart completionHandler:completionHandler];
}

+(BOOL)messagesAreTextOnly:(NSArray<CLBMessage *> *)messages {

    for (CLBMessage *message in messages) {
        if (![message.type isEqualToString:CLBMessageTypeText]) {
            return NO;
        }
    }

    return YES;
}

+(void)updateConversationById:(NSString *)conversationId withName:(nullable NSString *)displayName description:(nullable NSString *)description iconUrl:(nullable NSString *)iconUrl metadata:(nullable NSDictionary *)metadata completionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler {

    if (!displayName && !description && !iconUrl && !metadata) {
        if (completionHandler) {
            CLBEnsureMainThread(^{
                completionHandler(nil, nil);
            });
        }

        return;
    }

    [depManager.userSynchronizer updateConversationById:conversationId withName:displayName description:description iconUrl:iconUrl metadata:metadata completionHandler:completionHandler];
}

+ (void)fetchConfig {
    [depManager.configFetchScheduler scheduleImmediatelyWithCompletion:configFetchSchedulerCompletionHandler];
}

+ (void)loadConversation:(NSString *)conversationId completionHandler:(nullable void (^)(NSError  *_Nullable, NSDictionary  *_Nullable))completionHandler {
    if ([conversationId isEqualToString:depManager.conversation.conversationId]) {
        if (completionHandler) {
            CLBEnsureMainThread(^{
                completionHandler(nil, nil);
            });
        }
        return;
    }

    [depManager.userSynchronizer loadConversation:conversationId completionHandler:^(NSError *error, NSDictionary *userInfo) {
        if (completionHandler) {
            CLBEnsureMainThread(^{
                completionHandler(error, userInfo);
            });
        }
    }];
}

+ (void)getConversations:(void (^)(NSError  *_Nullable, NSArray  *_Nullable))completionHandler {
    [depManager.userSynchronizer loadConversations:completionHandler];
}

+ (void)getMoreConversations:(void (^)(NSError * _Nullable))completionHandler {
    [depManager.conversationController getMoreConversations:completionHandler];
}

+ (BOOL)hasMoreConversations {
    return [depManager.conversationController hasMoreConversations];
}

+(id<CLBConversationDelegate>)conversationDelegate {
    return conversationDelegate;
}

+ (void)updateConversationDelegate:(id<CLBConversationDelegate>)delegate {
    conversationDelegate = delegate;
    if (depManager != nil && depManager.conversation != nil) {
        depManager.conversation.delegate = delegate;
    }
}

@end
