//
//  CLBDependencyManager.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBConversationStorageManagerDelegate.h"
#import "CLBConfigFetchSchedulerDelegate.h"

@class CLBSettings;
@class CLBRemoteObjectSynchronizer;
@class CLBConfigFetchScheduler;
@class CLBConversationFetchScheduler;
@class CLBUserSynchronizer;
@class CLBConfig;
@class CLBConversation;
@class CLBConversationMonitor;
@class CLBLocationService;
@class CLBConversationViewController;
@class CLBConversationStorageManager;
@class CLBUser;

@interface CLBDependencyManager : NSObject <CLBConversationStorageManagerDelegate, CLBConfigFetchSchedulerDelegate>

- (void)createObjectsWithSettings:(CLBSettings *)settings;
- (void)createObjectsWithSettings:(CLBSettings *)settings config:(CLBConfig *)config;

- (instancetype)initWithSettings:(CLBSettings *)settings;

- (CLBConversation *)readConversation:(NSString *)conversationId;
- (CLBConversationViewController *)startConversationViewControllerWithStartingText:(NSString *)startingText;

@property (readonly) CLBSettings *sdkSettings;
@property CLBRemoteObjectSynchronizer* synchronizer;
@property CLBConfigFetchScheduler* configFetchScheduler;
@property CLBConversationFetchScheduler* conversationScheduler;
@property CLBUserSynchronizer* userSynchronizer;
@property CLBLocationService *locationService;
@property CLBConversationMonitor* conversationMonitor;
@property(readonly) CLBConfig* config;
@property(readonly) CLBUser* user;
@property(readonly) CLBConversation* conversation;
@property(readonly) CLBConversationStorageManager *conversationStorageManager;

@end
