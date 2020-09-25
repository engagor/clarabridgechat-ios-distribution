//
//  CLBConversationController.h
//  ClarabridgeChat
//
//  Created by Shona Nunez on 22/11/2019.
//  Copyright © 2019 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBConversationViewControllerDelegate.h"
#import "CLBConversationMonitor.h"
#import "CLBEventTypeFactoryDelegate.h"

@class CLBConversation, CLBConfig, CLBSettings, CLBUser;
@class CLBConversationFetchScheduler, CLBConversationStorageManager;
@protocol CLBUtilitySettings, CLBConversationFetchSchedulerProtocol, CLBRemoteObjectSynchronizerProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface CLBConversationController : NSObject <CLBConversationViewControllerDelegate, CLBConversationMonitorListener, CLBEventTypeFactoryDelegate>

- (instancetype)initWithFetchScheduler:(id<CLBConversationFetchSchedulerProtocol>)conversationFetchScheduler
                          synchronizer:(id<CLBRemoteObjectSynchronizerProtocol>)synchronizer
                                config:(CLBConfig *)config
                              settings:(CLBSettings *)settings
                       utilitySettings:(id<CLBUtilitySettings>)utilitySettings
                               storage:(CLBConversationStorageManager *)storage
                          conversation:(CLBConversation *)conversation
                                  user:(CLBUser *)user;

- (CLBConversation *)conversation:(NSString *)conversationId;

- (void)getConversationById:(NSString *)conversationId withCompletionHandler:(void (^)(NSError * _Nullable, CLBConversation * _Nullable))handler;
- (void)updateConversationList;
- (void)getMoreConversations:(void (^)(NSError * _Nullable))completionHandler;
- (BOOL)hasMoreConversations;

@property (nonatomic, copy, nullable) void (^reloadConversationList)(void);

@end

NS_ASSUME_NONNULL_END
