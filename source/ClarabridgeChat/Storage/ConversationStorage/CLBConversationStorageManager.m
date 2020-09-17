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

- (void)storeConversationList:(CLBConversationList *)conversationList {
    [self.listStorage storeConversationList:conversationList];
    [self addUnsavedConversations:conversationList];
}

- (BOOL)activeConversationIsUpToDate:(CLBConversationList *)conversationList {
    [self addUnsavedConversations:conversationList];
    return [self activeConversationMessagesAreUpToDate:conversationList];
}

- (void)addUnsavedConversations:(CLBConversationList *)conversationList {
    for (CLBConversation *conversation in conversationList.conversations) {
        CLBConversation *storedConversation = [self.storage findConversationById:conversation.conversationId];
        if (storedConversation == NULL) {
            [self.storage storeConversation:conversation]; //Important so notifications can be received for non-active conversations
        }
    }
}

- (BOOL)activeConversationMessagesAreUpToDate:(CLBConversationList *)conversationList {
    NSArray *sortedConversations = [conversationList.conversations sortedArrayUsingComparator:^NSComparisonResult(CLBConversation *firstConversation, CLBConversation *secondConversation) {
        return [firstConversation.lastUpdatedAt compare:secondConversation.lastUpdatedAt] == NSOrderedAscending;
    }];

    CLBConversation *latestConversation = sortedConversations.firstObject;
    CLBConversation *latestStoredConversation = [self.storage findConversationById: latestConversation.conversationId];

    CLBMessage *latestConversationMessage = latestConversation.messages.lastObject;
    CLBMessage *latestStoredConversationMessage = latestStoredConversation.messages.lastObject;

    //This can happen when a conversation is first started and a media message is sent as the first message
    //The media item needs to be sent before a message is created so in this scenario we won't have any messages
    if (latestConversationMessage == nil && latestStoredConversationMessage == nil) {
        return YES;
    }

    return latestConversationMessage == latestStoredConversationMessage;
}

- (BOOL)messagesAreInSyncInStorageForConversationId:(NSString *)conversationId {
    CLBConversation *conversation = [self.storage findConversationById:conversationId];
    CLBConversation *listConversation = [[self.listStorage getConversationList] getConversationById:conversationId];

    CLBMessage *latestStoredConversationMessage = conversation.messages.lastObject;
    CLBMessage *latestStoredConversationListMessage = listConversation.messages.lastObject;

    return latestStoredConversationMessage == latestStoredConversationListMessage;
}

//MARK: - CLBConversationPersistence

- (CLBConversation *)readConversation:(NSString *)conversationId {
    return [self.storage findConversationById:conversationId];
}

- (void)removeConversation:(NSString *)conversationId {
    [self.storage removeConversationById:conversationId];
    //Needs to be updated to remove from list as well
}

- (void)storeConversation:(CLBConversation *)conversation {
    [self.storage storeConversation:conversation];
    [self storeUpdatedConversationListWithConversation:conversation];
}

- (void)storeUpdatedConversationListWithConversation:(CLBConversation *)conversation {
    CLBConversationList *list = [self.listStorage getConversationList];
    [list appendConversationMessageToList:conversation];
    [self.listStorage storeConversationList:list];
}

- (void)conversationHasChanged:(CLBConversation *)conversation {
    [self.delegate conversationHasChanged:conversation];
}

@end
