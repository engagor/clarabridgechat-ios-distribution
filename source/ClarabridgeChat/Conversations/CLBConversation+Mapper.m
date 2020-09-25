//
//  CLBConversation+Mapper.m
//  ClarabridgeChat
//
//  Created by Thaciana Lima on 04/06/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBConversation+Mapper.h"
#import "CLBConversationViewModel.h"
#import "CLBParticipant.h"
#import "CLBLocalization.h"
#import "CLBMessage+Private.h"
#import "CLBUser+Private.h"

@implementation CLBConversation (Mapper)

- (CLBConversationViewModel *)conversationViewModelWithAppAvatarURLString:(NSString *)appAvatarUrlString appName:(NSString *)appName users:(NSArray<CLBUser *> *)users {
    NSString *lastMessage;
    if (self.messages.lastObject) {
        CLBMessage *message = self.messages.lastObject;
        lastMessage = [self buildLastMessageWithMessage:message andDefaultName:appName andUsers:users];
    } else {
        lastMessage = [CLBLocalization localizedStringForKey:@"No Messages"];
    }

    NSString *displayName = (self.displayName && self.displayName.length > 0) ? self.displayName : appName;

    NSString *avatarUrl = appAvatarUrlString;

    if (self.iconUrl) {
        avatarUrl = self.iconUrl;
    }

    CLBConversationViewModel *conversationViewModel = [[CLBConversationViewModel alloc] initWithDisplayName:displayName
                                                                                          andConversationId:self.conversationId
                                                                                             andLastUpdated:self.lastUpdatedAt
                                                                                             andLastMessage:lastMessage
                                                                                         andAvatarURLString:avatarUrl
                                                                                             andUnreadCount:self.unreadCount
                                                                                                 andAppName:appName];
    return conversationViewModel;
}


- (NSString *)buildLastMessageWithMessage:(CLBMessage *)message andDefaultName:(NSString *)defaultName andUsers:(NSArray<CLBUser *> *)users {
    NSString *messageCreator = defaultName;

   // If the message has no name, it is from the business.
    if (message.displayName) {
        if (message.isFromCurrentUser) {
            messageCreator = [CLBLocalization localizedStringForKey:@"You"];
        } else {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userId==%@", message.userId];
            CLBUser *foundUser = [users filteredArrayUsingPredicate:predicate].firstObject;
            if (foundUser) messageCreator = foundUser.firstName;
        }
    }

    if ([message.type isEqual: @"text"]) {
        return [NSString stringWithFormat:@"%@: %@", messageCreator, message.text];
    }
    else if ([message.type isEqual: @"image"]) {
        return [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"%@ sent an image"], messageCreator];
    }
    else if ([message.type isEqual: @"file"]) {
        return [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"%@ sent a file"], messageCreator];
    }
    else if ([message.type isEqual: @"form"]) {
        return [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"%@ sent a form"], messageCreator];
    } else {
        return [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"%@ sent a message"], messageCreator];
    }
}

@end
