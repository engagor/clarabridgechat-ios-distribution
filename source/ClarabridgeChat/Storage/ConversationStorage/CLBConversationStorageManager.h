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

- (CLBConversation * _Nullable)readConversation:(NSString *)conversationId;
- (void)removeConversation:(NSString *)conversationId;
- (void)storeConversation:(CLBConversation *)conversation;
- (void)clearStorage;

- (CLBConversationList * _Nullable)getConversationList;
- (void)storeConversationList:(CLBConversationList *)conversationList;
- (BOOL)activeConversationIsUpToDate:(CLBConversationList *)conversationList;

- (BOOL)messagesAreInSyncInStorageForConversationId:(NSString *)conversationId;

@property (nonatomic, weak) id<CLBConversationStorageManagerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
