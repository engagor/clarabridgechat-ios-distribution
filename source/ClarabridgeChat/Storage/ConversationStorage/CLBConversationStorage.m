//
//  CLBConversationStorage.m
//  ClarabridgeChat
//
//  Created by Alan Egan on 22/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import "CLBConversationStorage.h"
#import "CLBConversation.h"
#import "CLBConversation+Private.h"

@interface CLBConversationStorage ()

@property (nonatomic, strong) id<CLBStorage>storage;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CLBConversation *> *cache;

@end

@implementation CLBConversationStorage

- (instancetype)initWithStorage:(id<CLBStorage>)storage {
    if (self = [super init]) {
        _storage = storage;
        _cache = [@{} mutableCopy];
    }
    return self;
}

- (void)storeConversation:(CLBConversation *)conversation {
    if (!conversation || !conversation.conversationId) {
        return;
    }
    self.cache[conversation.conversationId] = conversation;
    [self.storage setObject:conversation forKey:conversation.conversationId];
}

- (CLBConversation * _Nullable)findConversationById:(NSString *)conversationId {
    if (!conversationId) {
        return nil;
    }

    CLBConversation *stored = self.cache[conversationId];
    if (stored) {
        [stored clearExpiredMessages];
        return stored;
    }

    CLBConversation *storage = [self.storage objectForKey:conversationId];
    [storage clearExpiredMessages];
    return storage;
}

- (void)removeConversationById:(NSString *)conversationId {
    if (!conversationId) {
        return;
    }
    
    [self.cache removeObjectForKey:conversationId];
    [self.storage removeObjectForKey:conversationId];
}

- (void)clear {
    [self.cache removeAllObjects];
    [self.storage clear];
}

@end
