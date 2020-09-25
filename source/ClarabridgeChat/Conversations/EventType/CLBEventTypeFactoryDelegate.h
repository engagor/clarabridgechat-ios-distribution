//
//  CLBEventTypeFactoryDelegate.h
//  ClarabridgeChat
//
//  Created by Shona Nunez on 17/02/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class CLBEventTypeFactory, CLBConversation, CLBMessage, CLBConversationActivity;

@protocol CLBEventTypeFactoryDelegate <NSObject>

- (BOOL)messagesAreInSyncInStorageForConversationId:(NSString *)conversationId;
- (void)currentConversationNeedsRefresh:(CLBConversation *)conversation;
- (void)currentConversationListNeedsRefresh;
- (void)showInAppNotificationForMessage:(CLBMessage *)message conversationId:(NSString *)conversationId;
- (void)updateLastUpdatedAtAndUnreadCountForMessage:(CLBMessage *)message conversationId:(NSString *)conversationId;
- (nullable CLBConversation *)conversationById:(NSString *)conversationId;
- (void)conversationRemoved:(CLBConversation *)conversation;
- (void)handleActivity:(CLBConversationActivity *)activity forConversation:(CLBConversation *)conversation;
- (void)currentConversationListNeedsRefreshWithPendingNotificationMessage:(CLBMessage *)pendingNotificationMessage
                                                pendingNotificationConversationId:(NSString *)pendingNotificationConversationId;

@end

NS_ASSUME_NONNULL_END
