//
//  CLBConversationFetchScheduler.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBConversationFetchSchedulerProtocol.h"

@class CLBConversation;
@class CLBInAppNotificationHandler;
@class CLBRemoteObjectSynchronizer;
@class CLBMessage;
@class CLBConversationMonitor;

@interface CLBConversationFetchScheduler : NSObject <CLBConversationFetchSchedulerProtocol>

- (instancetype)initWithConversation:(CLBConversation *)conversation
                 conversationMonitor:(CLBConversationMonitor *)conversationMonitor
                        notifHandler:(CLBInAppNotificationHandler *)notifHandler
                        synchronizer:(CLBRemoteObjectSynchronizer *)synchronizer;

- (void)sendNotificationReplyForMessage:(CLBMessage *)message conversationId:(NSString *)conversationId;

@property CLBRemoteObjectSynchronizer* synchronizer;
@property CLBInAppNotificationHandler* notifHandler;
@property (readonly) CLBConversation* conversation;

@end
