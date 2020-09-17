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

    self.conversations = conversationList.copy;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    @synchronized (self) {
        [coder encodeObject:self.conversations forKey:@"conversations"];
    }
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self = [super init];
    if (self) {
        _conversations = [coder decodeObjectOfClass:[NSArray class] forKey:@"conversations"];
    }
    return self;
}

- (CLBConversation * _Nullable)getConversationById:(NSString *)conversationId {
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"conversationId == %@", conversationId];
    CLBConversation *selectedConversation = [self.conversations filteredArrayUsingPredicate:filterPredicate].firstObject;
    return selectedConversation;
}

- (void)appendConversationMessageToList:(CLBConversation *)conversation {
    CLBConversation *listConversation = [self getConversationById:conversation.conversationId];

    if (listConversation == nil) {
        return;
    }

    NSUInteger index = [self.conversations indexOfObject:listConversation];
    CLBMessage *lastMessage = conversation.messages.lastObject;
    CLBMessage *lastListMessage = listConversation.messages.lastObject;

    if (lastMessage == lastListMessage || lastMessage == nil) {
        return;
    }

    listConversation = [self updateListConversation:listConversation withLatestMessage:lastMessage];
    NSMutableArray<CLBConversation *> *listConversations = [self.conversations mutableCopy];
    [listConversations replaceObjectAtIndex:index withObject:listConversation];
    self.conversations = listConversations;
}

- (CLBConversation *)updateListConversation:(CLBConversation *)conversation withLatestMessage:(CLBMessage *)message {
    NSMutableArray *messages = [conversation.messages mutableCopy];
    [messages removeAllObjects];
    [messages addObject:message];
    conversation.messages = messages;
    return conversation;
}

@end
