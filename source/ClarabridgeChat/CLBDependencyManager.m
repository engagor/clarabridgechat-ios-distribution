//
//  CLBDependencyManager.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBDependencyManager.h"
#import "CLBClarabridgeChatApiClient.h"
#import "CLBUserLifecycleManager.h"
#import "CLBImageLoader.h"
#import "CLBRemoteObjectSynchronizer.h"
#import "CLBConfigFetchScheduler.h"
#import "CLBConversationFetchScheduler.h"
#import "CLBUserSynchronizer.h"
#import "CLBUtility.h"
#import "CLBConfig.h"
#import "CLBInAppNotificationHandler.h"
#import "CLBConversation+Private.h"
#import "CLBUser+Private.h"
#import "CLBMZFayeClient.h"
#import "CLBConversationMonitor.h"
#import "CLBLocationService.h"
#import "CLBSettings+Private.h"
#import <UserNotifications/UserNotifications.h>
#import "ClarabridgeChat.h"
#import "ClarabridgeChat+Private.h"
#import "CLBConversationController.h"
#import "CLBClarabridgeChatUtilitySettings.h"
#import "CLBConversationStorage.h"
#import "CLBClarabridgeChatStorage.h"
#import "CLBClarabridgeChatSerializer.h"
#import "CLBScopeURLFactory.h"
#import "CLBScopeURLProvider.h"
#import "CLBClarabridgeChatFileIO.h"
#import "CLBConversationViewController.h"
#import "CLBConversationListStorage.h"
#import "CLBConversationList.h"
#import "CLBDependencyManager+Private.h"
#import "CLBConversationStorageManager.h"
#import "CLBHeaderFactory.h"


@interface CLBDependencyManager ()

@property CLBSettings *sdkSettings;
@property CLBConfig *config;
@property CLBUser* user;
@property CLBConversationViewController *conversationViewController;
@property CLBConversationController *conversationController;
@property CLBConversationStorage *conversationStorage;
@property CLBConversationListStorage *conversationListStorage;

@end

@implementation CLBDependencyManager

- (void)createObjectsWithSettings:(CLBSettings *)settings {
    [self createObjectsWithSettings:settings config:nil];
}

- (instancetype)initWithSettings:(CLBSettings *)settings  {
    self = [super init];
    if (self) {
        self.sdkSettings = settings;
        [self initUser];
        [self initConfig];
        [self initConfigFetchScheduler];
    }
    return self;
}

- (void)createObjectsWithSettings:(CLBSettings *)settings config:(CLBConfig *)config {
    if(!settings){
        return;
    }

    self.sdkSettings = settings;

    // ORDER MATTERS

    [self initConversationStorage];
    [self initConversationListStorage];
    [self initConversationStorageManager];

    [self initSynchronizer];
    [self initUser];
    [CLBUser setCurrentUser:self.user];

    self.userSynchronizer = [[CLBUserSynchronizer alloc] initWithUser:self.user
                                                         synchronizer:self.synchronizer
                                                                appId:self.sdkSettings.appId
                                                   retryConfiguration:self.config.retryConfiguration
                                                             settings:self.sdkSettings
                                                         conversation:self.conversation
                                           conversationStorageManager:self.conversationStorageManager];

    [self initConversation];

    self.userSynchronizer.conversationMonitor = self.conversationMonitor;
    self.locationService = [[CLBLocationService alloc] init];
}

- (void)initConversationListStorage {
    CLBClarabridgeChatSerializer *serializer = [[CLBClarabridgeChatSerializer alloc] init];
    CLBClarabridgeChatFileIO *fileIO = [[CLBClarabridgeChatFileIO alloc] init];
    CLBScopeURLFactory *scopeFactory = [[CLBScopeURLFactory alloc] init];
    id<CLBScopeURLProvider> provider = [scopeFactory urlProviderFor:CLBStorageScopeUser];
    CLBClarabridgeChatStorage *storage = [[CLBClarabridgeChatStorage alloc] initWithClass:[CLBConversationList class]
                                                             serializer:serializer
                                                                 fileIO:fileIO
                                                            urlProvider:provider];
    _conversationListStorage = [[CLBConversationListStorage alloc] initWithStorage:storage];
}

- (void)initConversationStorage {
    CLBClarabridgeChatSerializer *serializer = [[CLBClarabridgeChatSerializer alloc] init];
    CLBClarabridgeChatFileIO *fileIO = [[CLBClarabridgeChatFileIO alloc] init];
    CLBScopeURLFactory *scopeFactory = [[CLBScopeURLFactory alloc] init];
    id<CLBScopeURLProvider> provider = [scopeFactory urlProviderFor:CLBStorageScopeUser];
    CLBClarabridgeChatStorage *storage = [[CLBClarabridgeChatStorage alloc] initWithClass:[CLBConversation class]
                                                             serializer:serializer
                                                                 fileIO:fileIO
                                                            urlProvider:provider];
    _conversationStorage = [[CLBConversationStorage alloc] initWithStorage:storage];
}

- (void)initConversationStorageManager {
    _conversationStorageManager = [[CLBConversationStorageManager alloc] initWithStorage:self.conversationStorage
                                                                             listStorage:self.conversationListStorage];
    _conversationStorageManager.delegate = self;
}

-(void)initSynchronizer {
    CLBApiClient* apiClient = [[CLBClarabridgeChatApiClient alloc] initWithBaseURL:self.config.apiBaseUrl
                                                   authenticationDelegate:self.sdkSettings.authenticationDelegate
                                                               completion:^(NSString *jwt) {
        [CLBUserLifecycleManager setLastKnownJwt:jwt forAppId:self.sdkSettings.appId];
        self.sdkSettings.jwt = jwt;
    }];

    apiClient.headersBlock = ^NSDictionary *{
        return [CLBHeaderFactory authHeadersForAPIClient:self.sdkSettings];
    };

    self.synchronizer = [[CLBRemoteObjectSynchronizer alloc] initWithApiClient:apiClient];
}

-(void)initUser {
    self.user = [[CLBUser alloc] init];
    self.user.appId = self.sdkSettings.appId;
    [self.user readLocalProperties];
}

-(void)initConfig {
    self.config = [[CLBConfig alloc] initWithIntegrationId:self.sdkSettings.integrationId];
    self.config.apiBaseUrl = self.sdkSettings.configBaseUrl;
}

-(void)initConfigFetchScheduler {
    CLBApiClient *configApiClient = [[CLBApiClient alloc] initWithBaseURL:CLBGetConfigApiBaseUrlWithConfig(self.config, self.sdkSettings)];

    configApiClient.headersBlock = ^NSDictionary *{
        return [CLBHeaderFactory configAPIClientHeaders];
    };

    CLBRemoteObjectSynchronizer *synchronizer = [[CLBRemoteObjectSynchronizer alloc] initWithApiClient:configApiClient];
    self.configFetchScheduler = [[CLBConfigFetchScheduler alloc] initWithConfig:self.config synchronizer:synchronizer];
    self.configFetchScheduler.delegate = self;
}

- (void)handleUpdatedSettings {
    NSString *legacyDeviceIdentifier = [self getLegacyIdentifier];
    
    if (self.sdkSettings.authCode.length > 0) {
        [self.userSynchronizer consumeAuthCode:self.sdkSettings.authCode completionHandler:^(NSError *error, NSDictionary *userInfo) {
            [self handleConsumeAuthCodeResponse:error userInfo:userInfo];
        }];
    } else if (legacyDeviceIdentifier) {
        [self.userSynchronizer upgradeUserWithClientId:legacyDeviceIdentifier completionHandler:^() {
            [self upgradeLegacyIdentifier];
            [self completeInitialization];
        }];
    } else {
        [self completeInitialization];
    }
}

- (void)handleConsumeAuthCodeResponse:(NSError *)error userInfo:(NSDictionary *)userInfo {
    NSString* legacyDeviceIdentifier = [self getLegacyIdentifier];
    if (error) {
        self.config.validityStatus = CLBAppStatusInvalid;
        [self notifyInitializationFailedWithError:error
                                             code:userInfo[CLBErrorCodeIdentifier]
                                       statusCode:[userInfo[CLBStatusCodeIdentifier] integerValue]
                                      description:userInfo[CLBErrorDescriptionIdentifier]];
    } else {
        if (legacyDeviceIdentifier) {
            [self upgradeLegacyIdentifier];
        }
        [self completeInitialization];
    }
}

- (NSString *)getLegacyIdentifier {
    return CLBGetLegacyUniqueDeviceIdentifier();
}

- (void)upgradeLegacyIdentifier {
    CLBUpgradeLegacyUniqueDeviceIdentifier();
}

- (void)notifyInitializationFailedWithError:(NSError *)error code:(NSString *)errorCode statusCode:(NSInteger) statusCode description:(NSString *)errorDescription {
    NSDictionary *userInfo = @{
        CLBErrorCodeIdentifier: errorCode ?: @"",
        CLBStatusCodeIdentifier: [NSNumber numberWithInteger:statusCode],
        CLBErrorDescriptionIdentifier: errorDescription ?: @""
    };

    if (self.configFetchScheduler.fetchCompletionHandler) {
        self.configFetchScheduler.fetchCompletionHandler(error, userInfo);
    }
}

- (void)completeInitialization {
    if (self.sdkSettings.isAuthenticatedUser) {
        [self.userSynchronizer logInWithCompletionHandler:^(NSError *error, NSDictionary *userInfo) {
            [self userUpdated:error withUserInfo:userInfo];
        }];
    } else if (self.sdkSettings.appUserId && self.sdkSettings.sessionToken) {
        self.userSynchronizer.user.appUserId = self.sdkSettings.appUserId;
        // Anonymous user, fetch for updates
        [self.userSynchronizer fetchUserWithCompletionHandler:^(NSError *error, NSDictionary *userInfo) {
            [self handleFetchAnonymousUser:error userInfo:userInfo];
        }];
    } else {
        // No stored user, or stored information is incomplete
        // Start in a fresh state
        self.config.validityStatus = CLBAppStatusValid;
        [self notifyInitializationSuccessful];

        if (self.config.pushEnabled) {
            [self registerForRemoteNotifications];
        }
    }
}

- (void)handleFetchAnonymousUser:(NSError *)error userInfo:(NSDictionary *)userInfo {
    NSInteger statusCode = [userInfo[CLBStatusCodeIdentifier] integerValue];

    if (statusCode == 401 || statusCode == 404 || statusCode == 403) {
        [self forgetUser];
        error = nil;
        userInfo = nil;
    } else if (!error) {
        BOOL isValidClient = [self clientsArrayContainsCurrentClient];
        if (!isValidClient) {
            [self forgetUser];
            error = nil;
            userInfo = nil;
        }
    }
    [self userUpdated:error withUserInfo:userInfo];
}

- (void)userUpdated:(NSError *)error withUserInfo:(NSDictionary *)userInfo {
    if (!error) {
        self.config.validityStatus = CLBAppStatusValid;
        [self notifyInitializationSuccessful];
        [self registerForRemoteNotifications];
    } else {
        self.config.validityStatus = CLBAppStatusInvalid;
        [self notifyInitializationFailedWithError:error
                                             code:userInfo[CLBErrorCodeIdentifier]
                                       statusCode:[userInfo[CLBStatusCodeIdentifier] integerValue]
                                      description:userInfo[CLBErrorDescriptionIdentifier]];
    }
}

- (BOOL)clientsArrayContainsCurrentClient {
    NSString* clientId = CLBGetUniqueDeviceIdentifier();

    NSArray<NSDictionary*>* clients = self.userSynchronizer.user.clients;
    if (!clients || clients.count == 0) {
        return NO;
    }

    NSInteger clientIndex = [clients indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"id"] isEqualToString:clientId]) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];

    return clientIndex != NSNotFound;
}

- (void)forgetUser {
    // Session token invalid. Clear local credentials and allow usage as a new user
    self.sdkSettings.appUserId = nil;
    self.sdkSettings.sessionToken = nil;
    [CLBUserLifecycleManager clearAppUserIdForAppId:self.config.appId];
    [CLBUserLifecycleManager clearSessionTokenForAppId:self.config.appId];
    [[ClarabridgeChat getUserLifecycleManager] rebuildDependenciesWithUserId:nil jwt:nil];
    [self.conversationStorageManager clearStorage];
}

- (void)notifyInitializationSuccessful {
    if (self.configFetchScheduler.fetchCompletionHandler) {
        self.configFetchScheduler.fetchCompletionHandler(nil, nil);
    }
}

- (void)registerForRemoteNotifications {
    if (self.config.pushEnabled) {
        CLBEnsureMainThread(^{
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        });
    }
}

- (void)initConversation {
    CLBConversation *conversation = [CLBConversation conversationWithAppId:self.config.appId
                                                                      user:self.user
                                                                  settings:self.sdkSettings];

    self.conversationMonitor = [[CLBConversationMonitor alloc] initWithUser:self.user config:self.config];
    [self loadConversation:conversation];
}

-(CLBConversation*)conversation {
    return self.conversationScheduler.conversation; //This pathing is necessary for Notifications - involves CLBAppDelegate
}

- (CLBConversation *)readConversation:(NSString *)conversationId {
    return [self.conversationStorageManager readConversation:conversationId];
}

- (void)loadConversation:(CLBConversation *)conversation {
    conversation.persistence = self.conversationStorageManager;
    conversation.delegate = [ClarabridgeChat conversationDelegate];
    self.userSynchronizer.conversation = conversation;

    UNUserNotificationCenter *currentNotificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    if (currentNotificationCenter != nil) {
        CLBInAppNotificationHandler *notifHandler = [[CLBInAppNotificationHandler alloc] initWithSettings:self.sdkSettings
                                                                                   userNotificationCenter:[UNUserNotificationCenter currentNotificationCenter]
                                                                                             conversation:conversation];

        self.conversationScheduler = [[CLBConversationFetchScheduler alloc] initWithConversation:conversation
                                                                             conversationMonitor:self.conversationMonitor
                                                                                    notifHandler:notifHandler
                                                                                    synchronizer:self.synchronizer];
    }

    CLBClarabridgeChatUtilitySettings *utilitySettings = [CLBClarabridgeChatUtilitySettings new];
    self.conversationController = [[CLBConversationController alloc] initWithFetchScheduler:self.conversationScheduler
                                                                               synchronizer:self.synchronizer
                                                                                     config:self.config
                                                                                   settings:self.sdkSettings
                                                                            utilitySettings:utilitySettings
                                                                                    storage:self.conversationStorageManager
                                                                               conversation:conversation
                                                                                       user:self.user];
    self.conversationMonitor.listener = self.conversationController;

    if (self.conversationViewController) {
        self.conversationViewController.delegate = self.conversationController;
        [self.conversationViewController updateConversationId:conversation.conversationId];
    }
}

- (CLBConversationViewController *)startConversationViewControllerWithStartingText:(NSString *)startingText {
    self.conversationViewController = nil;
    CLBConversationViewController *conversationViewController = [[CLBConversationViewController alloc] initWithDeps:self];
    
    if (self.conversationController) {
        conversationViewController.delegate = self.conversationController;
    }
    conversationViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    conversationViewController.startingText = startingText;
    self.conversationViewController = conversationViewController;
    return conversationViewController;
}

//MARK: - CLBConversationStorageManagerDelegate

- (void)conversationHasChanged:(CLBConversation *)conversation {
    if (self.conversationViewController != nil && [CLBConversationViewController isConversationShown]) {
        [self.conversationViewController updateConversationId:conversation.conversationId];
        [self loadConversation:conversation];
    } else {
        [self loadConversation:conversation];
    }
}

- (void)handleSendPendingMessage:(CLBMessage *)message conversationId:(NSString *)conversationId {
    CLBConfig *config = self.configFetchScheduler.config;

    if (config.multiConvoEnabled) {
        if ([conversationId isEqualToString:self.conversation.conversationId]) {
            // Reply intended for the conversation that's currently loaded, send as usual
            [self.conversation sendMessage:message];
        } else {
            // Reply intended for another conversation, post without storing in local conversation
            [self.conversationScheduler sendNotificationReplyForMessage:message conversationId:conversationId];
        }
    } else {
        [self.conversation sendMessage:message];
    }
}

// MARK: - CLBConfigFetchSchedulerDelegate

- (void)configFetchScheduler:(CLBConfigFetchScheduler *)scheduler didUpdateAppId:(NSString*)appId {
    self.sdkSettings.appId = appId;
}
@end
