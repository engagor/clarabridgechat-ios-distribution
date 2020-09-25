//
//  CLBConversationStorageManager.m
//  ClarabridgeChat
//
//  Created by Shona Nunez on 28/01/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBConversationStorageManager.h"
#import "CLBConversation.h"
#import "CLBConversation+Private.h"
#import "CLBConversationStorage.h"
#import "CLBConversationListStorage.h"
#import "CLBConversationList.h"
#import "CLBConversationStorageManagerDelegate.h"

@interface CLBConversationStorageManager()

@property CLBConversationStorage *storage;
@property CLBConversationListStorage *listStorage;

@end

@implementation CLBConversationStorageManager

// MARK: - Public methods

- (instancetype)initWithStorage:(CLBConversationStorage *)storage listStorage:(CLBConversationListStorage *)listStorage {
    self = [super init];
    if (self) {
        _storage = storage;
        _listStorage = listStorage;
    }
    return self;
}

- (void)clearStorage {
    [self.storage clear];
    [self.listStorage clear];
}

- (CLBConversationList *)getConversationList {
    return [self.listStorage getConversationList];
}

- (void)storeConversationList:(CLBConversationList *)conversationList activeConversationId:(NSString *)activeConversationId {
    [self.listStorage storeConversationList:conversationList];
    if (activeConversationId) {
        [self clearNonActiveConversationsWithActiveConversationId:activeConversationId];
    }
    [self storeNonActiveConversations:conversationList activeConversationId:activeConversationId];
}

- (void)mergeConversationListWith:(CLBConversationList *)otherConversationList activeConversationId:(NSString *)activeConversationId {
    CLBConversationList *conversationList = [self.listStorage getConversationList];
    if (conversationList) {
        [conversationList updateWithConversationList:otherConversationList];
    } else {
        conversationList = otherConversationList;
    }

    [self.listStorage storeConversationList:conversationList];
    [self storeNonActiveConversations:conversationList activeConversationId:activeConversationId];
}

- (BOOL)messagesAreInSyncInStorageForConversationId:(NSString *)conversationId {
    CLBConversation *conversation = [self.storage findConversationById:conversationId];
    CLBConversation *listConversation = [[self.listStorage getConversationList] getConversationById:conversationId];

    CLBMessage *latestStoredConversationMessage = conversation.messages.lastObject;
    CLBMessage *latestStoredConversationListMessage = listConversation.messages.lastObject;

    return latestStoredConversationMessage == latestStoredConversationListMessage;
}

// MARK: CLBConversationPersistence

- (void)storeConversation:(CLBConversation *)conversation {
    [self.storage storeConversation:conversation];
    [self updateConversationListWithConversation:conversation];
}

- (CLBConversation *)readConversation:(NSString *)conversationId {
    return [self.storage findConversationById:conversationId];
}

- (void)removeConversation:(CLBConversation *)conversation {
    [self.storage removeConversationById:conversation.conversationId];
    CLBConversationList *list = [self.listStorage getConversationList];
    [list removeConversationFromList:conversation];
    [self.listStorage storeConversationList:list];
}

- (void)conversationHasChanged:(CLBConversation *)conversation {
    [self.delegate conversationHasChanged:conversation];
}

// MARK: - Private Methods

- (void)storeNonActiveConversations:(CLBConversationList *)conversationList activeConversationId:(NSString *)activeConversationId {
    for (CLBConversation *conversation in conversationList.conversations) {
        CLBConversation *storedConversation = [self.storage findConversationById:conversation.conversationId];
        if (!storedConversation || conversation.conversationId != activeConversationId) {
            [self.storage storeConversation:conversation]; //Important so notifications can be received for non-active conversations
        }
    }
}

- (void)clearNonActiveConversationsWithActiveConversationId:(NSString *)activeConversationId {
    CLBConversation *activeConversation = [self readConversation:activeConversationId];
    [self.storage clear];
    [self.storage storeConversation:activeConversation];
}

- (void)updateConversationListWithConversation:(CLBConversation *)conversation {
    CLBConversationList *list = [self.listStorage getConversationList];
    [list updateWithConversation:conversation];
    [self.listStorage storeConversationList:list];
}

@end
