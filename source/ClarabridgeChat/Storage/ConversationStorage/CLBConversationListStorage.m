//
//  CLBConversationListStorage.m
//  ClarabridgeChat
//
//  Created by Alan O'Connor on 15/01/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBConversationListStorage.h"
#import "CLBConversationList.h"

@interface CLBConversationListStorage ()
@property (nonatomic, strong) id<CLBStorage>storage;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CLBConversationList *> *cache;
@end

@implementation CLBConversationListStorage

- (instancetype)initWithStorage:(id<CLBStorage>)storage {
    self = [super init];
    if (self) {
        _storage = storage;
        _cache = [@{} mutableCopy];
    }
    return self;
}

- (void)storeConversationList:(CLBConversationList *)conversationList {
    if (!conversationList) {
        return;
    }

    self.cache[@"conversations"] = conversationList;

    NSArray *firstTenConversations = [conversationList.conversations subarrayWithRange:NSMakeRange(0, MIN(10, conversationList.conversations.count))];
    CLBConversationList *listForFileStorage = [conversationList copy];
    listForFileStorage.conversations = firstTenConversations;
    [self.storage setObject:listForFileStorage forKey:@"conversations"];
}

- (CLBConversationList *)getConversationList {
    CLBConversationList *stored = self.cache[@"conversations"];
    if (stored) {
        return stored;
    }
    return [self.storage objectForKey:@"conversations"];
}

- (void)clear {
    [self.cache removeAllObjects];
    [self.storage clear];
}

@end
