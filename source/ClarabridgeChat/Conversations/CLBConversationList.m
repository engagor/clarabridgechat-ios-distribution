//
//  CLBConversationList.m
//  ClarabridgeChat
//
//  Created by Alan O'Connor on 15/01/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBConversationList.h"
#import "CLBConversation+Private.h"
#import "CLBUser+Private.h"
#import "CLBUtility.h"

@interface CLBConversationList ()

@property NSString *appId;
@property CLBUser *user;

@end

@implementation CLBConversationList

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithAppId:(NSString *)appId user:(CLBUser *)user {
    self = [super init];
    if (self) {
        _appId = appId;
        _user = user;
    }
    return self;
}

- (void)deserialize:(NSDictionary *)object {
    NSMutableArray *conversationList = [NSMutableArray new];

    for (NSDictionary *conversationObject in object[@"conversations"]) {
        CLBConversation *conversation = [[CLBConversation alloc] initWithAppId:self.appId user:self.user];
        [conversation deserialize:conversationObject];
        [conversationList addObject:conversation];
    }

    NSMutableArray<CLBUser *> *users = [NSMutableArray new];
    NSDictionary *userObjects = object[@"appUsers"];

    [userObjects enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull userId, NSDictionary *  _Nonnull obj, BOOL * _Nonnull stop) {
        CLBUser *user = [[CLBUser alloc] init];

        [user setUserId:userId];
        [user setFirstName:obj[@"givenName"]];
        [user setLastName:obj[@"surname"]];
        [user setExternalId:obj[@"userId"]];

        [users addObject:user];
    }];

    NSDictionary *conversationsPaginationObject = object[@"conversationsPagination"];
    BOOL hasMore = [[conversationsPaginationObject valueForKey:@"hasMore"] boolValue];

    self.hasMore = hasMore;
    self.conversations = conversationList.copy;
    self.users = users.copy;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    @synchronized (self) {
        [coder encodeObject:self.conversations forKey:@"conversations"];
        [coder encodeObject:self.conversations forKey:@"appUsers"];
    }
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self = [super init];
    if (self) {
        _conversations = [coder decodeObjectOfClass:[NSArray class] forKey:@"conversations"];
        _conversations = [coder decodeObjectOfClass:[NSArray class] forKey:@"appUsers"];
    }
    return self;
}

- (CLBConversation * _Nullable)getConversationById:(NSString *)conversationId {
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"conversationId == %@", conversationId];
    CLBConversation *selectedConversation = [self.conversations filteredArrayUsingPredicate:filterPredicate].firstObject;
    return selectedConversation;
}

- (void)updateWithConversation:(CLBConversation *)conversation {
    NSUInteger index = [self.conversations indexOfObjectPassingTest:^BOOL(CLBConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.conversationId isEqualToString:conversation.conversationId];
    }];

    if (index == NSNotFound) return;

    CLBConversation *conversationCopy = conversation.copy;
    if (conversationCopy.messages.count > 1) {
        conversationCopy.messages = @[conversationCopy.messages.lastObject];
    }

    NSMutableArray *mutableConversations = self.conversations.mutableCopy;
    [mutableConversations replaceObjectAtIndex:index withObject:conversationCopy];
    
    self.conversations = mutableConversations.copy;
    [self sortConverations];
}

- (void)removeConversationFromList:(CLBConversation *)conversation {
    NSMutableArray<CLBConversation *> *listConversations = [self.conversations mutableCopy];
    [self.conversations enumerateObjectsUsingBlock:^(CLBConversation *currentConversation, NSUInteger index, BOOL *stop) {
        if ([currentConversation.conversationId isEqualToString:conversation.conversationId]) {
            [listConversations removeObjectAtIndex:index];
        }
    }];
    self.conversations = listConversations;
}

- (void)updateWithConversationList:(CLBConversationList *)conversationList {
    NSMutableArray<CLBConversation *> *uniqueConversations = [self.conversations mutableCopy];
    for (CLBConversation *conversation in conversationList.conversations) {
        NSUInteger idx = [self.conversations indexOfObjectPassingTest:^BOOL(CLBConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.conversationId isEqualToString:conversation.conversationId];
        }];
        if (idx == NSNotFound) {
            [uniqueConversations addObject:conversation];
        } else {
            [uniqueConversations replaceObjectAtIndex:idx withObject:conversation];
        }
    }

    NSMutableArray<CLBUser *> *uniqueUsers = [self.users mutableCopy];
    for (CLBUser *user in conversationList.users) {
        NSUInteger idx = [self.users indexOfObjectPassingTest:^BOOL(CLBUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.externalId isEqualToString:user.externalId];
        }];
        if (idx == NSNotFound) {
            [uniqueUsers addObject:user];
        } else {
            [uniqueUsers replaceObjectAtIndex:idx withObject:user];
        }
    }

    self.conversations = [uniqueConversations copy];
    self.users = [uniqueUsers copy];
    self.hasMore = conversationList.hasMore;

    [self sortConverations];
}

- (void)sortConverations {
    if (!self.conversations || self.conversations.count == 0) return;

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUpdatedAt" ascending:NO];
    NSArray<CLBConversation *> *sortedConversations = [self.conversations sortedArrayUsingDescriptors:@[sortDescriptor]];
    self.conversations = sortedConversations;
}

- (nonnull CLBConversationList*)copyWithZone:(nullable NSZone *)zone {
    CLBConversationList *copy = [[CLBConversationList allocWithZone:zone] init];

    if (copy) {
        copy.conversations = [_conversations copyWithZone:zone];
        copy.users = [_users copyWithZone:zone];
        copy.hasMore = _hasMore;
        copy.appId = _appId;
        copy.user = _user;
    }

    return copy;
}

@end
