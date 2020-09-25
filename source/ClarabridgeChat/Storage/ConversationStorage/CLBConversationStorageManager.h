//
//  CLBConversationStorageManager.h
//  ClarabridgeChat
//
//  Created by Shona Nunez on 28/01/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBConversationPersistence.h"

@class CLBConversation, CLBConversationList, CLBConversationStorage, CLBConversationListStorage;
@protocol CLBConversationStorageManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

CLB_FINAL_CLASS
@interface CLBConversationStorageManager : NSObject <CLBConversationPersistence>

- (instancetype)initWithStorage:(CLBConversationStorage *)storage listStorage:(CLBConversationListStorage *)listStorage;

- (void)clearStorage;

- (CLBConversationList * _Nullable)getConversationList;

/// Stores the conversation list received.
/// If any conversation list already exists, that will be overriden and data relating to that will be cleared.
/// @param conversationList Conversation list to store.
/// @param activeConversationId Id of the current active conversation. It should be `nil` if no active conversation is present.
- (void)storeConversationList:(CLBConversationList *)conversationList activeConversationId:(NSString * _Nullable)activeConversationId;


/// Merges the exitisting conversation list with the conversation list received.
/// @param otherConversationList Conversation list to merge with the existing one.
/// @param activeConversationId Id of the current active conversation. It should be `nil` if no active conversation is present.
- (void)mergeConversationListWith:(CLBConversationList *)otherConversationList activeConversationId:(NSString * _Nullable)activeConversationId;

- (BOOL)messagesAreInSyncInStorageForConversationId:(NSString *)conversationId;

@property (nonatomic, weak) id<CLBConversationStorageManagerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
