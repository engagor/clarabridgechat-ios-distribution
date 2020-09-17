//
//  CLBEventTypeFactory.m
//  ClarabridgeChat
//
//  Created by Shona Nunez on 14/01/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBEventTypeFactory.h"
#import "CLBConversation.h"
#import "CLBConversation+Private.h"
#import "CLBConversationActivity+Private.h"
#import "CLBMessageAction+Private.h"
#import "CLBMessage+Private.h"
#import "CLBUtilitySettings.h"
#import "CLBEventTypeFactoryDelegate.h"
#import "CLBUser+Private.h"

NSString *const CLBEventTypeMessageString = @"message";
NSString *const CLBEventTypeUploadFailedString = @"upload:failed";
NSString *const CLBEventTypeActivityString = @"activity";

NSString *const CLBEventTypeParticipantAddedString = @"participant:added";
NSString *const CLBEventTypeParticipantRemovedString = @"participant:removed";

NSString *const CLBEventTypeConversationAddedString = @"conversation:added";
NSString *const CLBEventTypeConversationRemovedString = @"conversation:removed";

NSString *const CLBEventConversation = @"conversation";
NSString *const CLBEventParticipant = @"participant";
NSString *const CLBEventConversationId = @"_id";
NSString *const CLBEventMessage = @"message";
NSString *const CLBEventSource = @"source";
NSString *const CLBEventSourceId = @"id";
NSString *const CLBEventTypeString = @"type";
NSString *const CLBEventAppUserId = @"appUserId";
NSString *const CLBEventAppMakerString = @"appMaker";
NSString *const CLBEventAppMakerLastRead = @"appMakerLastRead";
NSString *const CLBEventAuthorId = @"authorId";

@interface CLBEventTypeFactory()

@property CLBConversation *conversation;
@property id<CLBUtilitySettings> utilitySettings;

@end

@implementation CLBEventTypeFactory

- (instancetype)initWithConversation:(CLBConversation *)conversation
                     utilitySettings:(id<CLBUtilitySettings>)utilitySettings {
    self = [super init];
    if (self) {
        self.conversation = conversation;
        self.utilitySettings = utilitySettings;
    }
    return self;
}

- (CLBEventType)eventTypeFromString:(NSString *)type {
    if([type isEqualToString:CLBEventTypeMessageString]) {
        return CLBEventTypeMessage;
    } else if([type isEqualToString:CLBEventTypeUploadFailedString]) {
        return CLBEventTypeUploadFailed;
    } else if([type isEqualToString:CLBEventTypeActivityString]) {
        return CLBEventTypeActivity;
    } else if ([type isEqualToString:CLBEventTypeConversationRemovedString]) {
        return CLBEventTypeConversationRemoved;
    } else if ([type isEqualToString:CLBEventTypeParticipantAddedString]) {
        return CLBEventTypeParticipantAdded;
    } else if ([type isEqualToString:CLBEventTypeParticipantRemovedString]) {
        return CLBEventTypeParticipantRemoved;
    } else if ([type isEqualToString:CLBEventTypeConversationAddedString]) {
        return CLBEventTypeConversationAdded;
    } else {
        return CLBEventTypeUnknown;
    }
}

- (void)handleEventType:(CLBEventType)type withEvent:(NSDictionary *)event {
    switch (type) {
        case CLBEventTypeMessage:
            [self handleMessageEvent:event];
            break;
        case CLBEventTypeUploadFailed:
            [self handleUploadFailedEvent:event];
            break;
        case CLBEventTypeActivity:
            [self handleActivityEvent:event];
            break;
        case CLBEventTypeConversationRemoved:
            [self handleConversationRemovedEvent:event];
            break;
        case CLBEventTypeConversationAdded:
        case CLBEventTypeParticipantRemoved:
        case CLBEventTypeParticipantAdded:
            [self handleParticipantsModified:event];
            break;
        default:
            break;
    }
}

- (void)handleConversationRemovedEvent:(NSDictionary *)event {
    NSString *conversationId = event[CLBEventConversation][CLBEventConversationId];
    BOOL isEventForCurrentConversation = [self isEventConversationId:conversationId forCurrentConversation:self.conversation];

    CLBConversationActivity *conversationActivity = [[CLBConversationActivity alloc] initWithDictionary:event[CLBEventTypeActivityString]];
    conversationActivity.conversationId = event[CLBEventConversation][CLBEventConversationId];
    conversationActivity.type = event[CLBEventTypeString];

    if (![self isValidActivity:conversationActivity]) {
        return;
    }

    if (isEventForCurrentConversation) {
        [self.delegate conversationRemoved:conversationId];
        [self.delegate handleActivity:conversationActivity forConversation:self.conversation];
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(conversationById:)]) {
            CLBConversation *conversation = [self.delegate conversationById:conversationId];
            if (self.conversation.delegate && [self.conversation.delegate respondsToSelector:@selector(conversation:didReceiveActivity:)]) {
                [self.conversation.delegate conversation:conversation didReceiveActivity:conversationActivity];
            }
        }
    }

    [self.delegate currentConversationListNeedsRefresh];
}

- (void)handleParticipantsModified:(NSDictionary *)event {
    [self.delegate currentConversationListNeedsRefresh];
    NSString *conversationId = event[CLBEventConversation][CLBEventConversationId];
    BOOL isEventForCurrentConversation = [self isEventConversationId:conversationId forCurrentConversation:self.conversation];

    CLBConversationActivity *activity = [[CLBConversationActivity alloc] init];
    activity.conversationId = conversationId;
    activity.appUserId = event[CLBEventParticipant][CLBEventAppUserId];
    activity.type = event[CLBEventTypeString];

    if(![self isValidActivity:activity]) {
        return;
    }

    if (isEventForCurrentConversation) {
        [self.delegate currentConversationNeedsRefresh:self.conversation];
        [self.delegate handleActivity:activity forConversation:self.conversation];
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(conversationById:)]) {
            CLBConversation *conversation = [self.delegate conversationById:conversationId];
            if (self.conversation.delegate && [self.conversation.delegate respondsToSelector:@selector(conversation:didReceiveActivity:)]) {
                [self.conversation.delegate conversation:conversation didReceiveActivity:activity];
            }
        }
    }
}

- (void)handleMessageEvent:(NSDictionary *)event {
    NSString *conversationId = event[CLBEventConversation][CLBEventConversationId];
    BOOL isEventForCurrentConversation = [self isEventConversationId:conversationId forCurrentConversation:self.conversation];

    NSDictionary *messagePayload = event[CLBEventMessage];
    NSString *authorId = messagePayload[CLBEventAuthorId];
    BOOL isFromCurrentUser = [self.conversation.user.appUserId isEqualToString:authorId];

    CLBMessage *message = [[CLBMessage alloc] initWithDictionary:messagePayload setIsFromCurrentUser:isFromCurrentUser];
    message.conversation = self.conversation;

    if (isEventForCurrentConversation) {
        [self addMessageOrHandleSuccessfulUploadEvent:event message:message];
    } else if (!isEventForCurrentConversation) {
        [self showInAppNotificationForEvent:event message:message conversationId:conversationId];
    }
}

- (BOOL)sourceIdMatchesIdentifier:(NSString *)sourceId {
    return [sourceId isEqualToString:[self.utilitySettings getUniqueDeviceIdentifier]];
}

- (BOOL)isMediaType:(CLBMessage *)message {
    return [@[CLBMessageTypeFile, CLBMessageTypeImage] containsObject:message.type];
}

- (void)addMessageOrHandleSuccessfulUploadEvent:(NSDictionary *)event message:(CLBMessage *)message {
    NSDictionary *messagePayload = event[CLBEventMessage];
    NSString *sourceId = messagePayload[CLBEventSource][CLBEventSourceId];

    if (sourceId != nil && [self sourceIdMatchesIdentifier:sourceId]) {
        if ([self isMediaType:message]) {
            [self.conversation handleSuccessfulUpload:message];
        }
        [self.delegate updateParticipantListForConversationId:self.conversation.conversationId withEvent:event isActiveConversation:YES];
    } else {
        [self handleMessageEvent:event message:message];
    }
}

- (void)handleMessageEvent:(NSDictionary *)event message:(CLBMessage *)message {
    if ([self.delegate messagesAreInSyncInStorageForConversationId:self.conversation.conversationId]) {
        [self.conversation addMessage:message];
        [self.delegate updateParticipantListForConversationId:self.conversation.conversationId withEvent:event isActiveConversation:YES];
    } else {
        [self.delegate currentConversationNeedsRefresh:self.conversation];
    }
}

- (void)showInAppNotificationForEvent:(NSDictionary *)event message:(CLBMessage *)message conversationId:(NSString *)conversationId {
    [self.delegate showInAppNotificationForMessage:message conversationId:conversationId];
    [self.delegate updateParticipantListForConversationId:conversationId withEvent:event isActiveConversation:NO];

}

- (void)handleUploadFailedEvent:(NSDictionary *)event {
    NSString *conversationId = event[CLBEventConversation][CLBEventConversationId];
    BOOL isEventForCurrentConversation = [self isEventConversationId:conversationId forCurrentConversation:self.conversation];

    if (isEventForCurrentConversation) {
        CLBFailedUpload *failedUpload = [[CLBFailedUpload alloc] initWithDictionary:event];

        if (failedUpload.messageId) {
            [self.conversation handleFailedUpload:failedUpload];
        }
    }
}

- (void)handleActivityEvent:(NSDictionary *)event {
    NSString *conversationId = event[CLBEventConversation][CLBEventConversationId];
    BOOL isEventForCurrentConversation = [self isEventConversationId:conversationId forCurrentConversation:self.conversation];
    CLBConversationActivity *conversationActivity = [[CLBConversationActivity alloc] initWithDictionary:event[CLBEventTypeActivityString]];
    conversationActivity.conversationId = conversationId;
    conversationActivity.appUserId = event[CLBEventTypeActivityString][CLBEventAppUserId];

    if(![self isValidActivity:conversationActivity]) {
        return;
    }

    if ([CLBConversationActivityTypeConversationRead isEqualToString:conversationActivity.type]) {
        if ([conversationActivity.role isEqualToString:CLBEventAppMakerString]) {
            conversationActivity.appMakerLastRead = [NSDate dateWithTimeIntervalSince1970:[event[CLBEventConversation][CLBEventAppMakerLastRead] doubleValue]];
        }
    }

    if (isEventForCurrentConversation) {
        [self.delegate handleActivity:conversationActivity forConversation:self.conversation];
    } else {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(conversationById:)]) {
            CLBConversation *conversation = [self.delegate conversationById:conversationId];

            if (self.conversation.delegate != nil && [self.conversation.delegate respondsToSelector:@selector(conversation:didReceiveActivity:)]) {
                [self.conversation.delegate conversation:conversation didReceiveActivity:conversationActivity];
            }
        }
    }
}

- (BOOL)isValidActivity:(CLBConversationActivity *)activity {
    NSArray *supportedActivities = @[CLBConversationActivityTypeTypingStart, CLBConversationActivityTypeTypingStop, CLBConversationActivityTypeConversationRead, CLBConversationActivityTypeConversationAdded, CLBConversationActivityTypeConversationRemoved, CLBConversationActivityTypeParticipantAdded, CLBConversationActivityTypeParticipantRemoved];
    return [supportedActivities containsObject:activity.type];
}

- (BOOL)isEventConversationId:(NSString *)conversationId forCurrentConversation:(CLBConversation *)conversation {
    return conversation.conversationId.length > 0 && [conversationId isEqualToString:conversation.conversationId];
}

@end
