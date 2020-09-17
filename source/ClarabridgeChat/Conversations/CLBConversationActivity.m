//
//  CLBConversationActivity.m
//  ClarabridgeChat
//
//  Copyright © 2016 Radialpoint. All rights reserved.
//

#import "CLBConversationActivity.h"
#import "CLBConversationActivity+Private.h"

NSString *const CLBConversationActivityTypeTypingStart = @"typing:start";
NSString *const CLBConversationActivityTypeTypingStop = @"typing:stop";
NSString *const CLBConversationActivityTypeConversationRead = @"conversation:read";
NSString *const CLBConversationActivityTypeConversationAdded = @"conversation:added";
NSString *const CLBConversationActivityTypeConversationRemoved = @"conversation:removed";
NSString *const CLBConversationActivityTypeParticipantAdded = @"participant:added";
NSString *const CLBConversationActivityTypeParticipantRemoved = @"participant:removed";

NSString *const CLBConversationActivityDataNameKey = @"name";
NSString *const CLBConversationActivityDataAvatarUrlKey = @"avatarUrl";
NSString *const CLBConversationActivityConversationKey = @"conversation";
NSString *const CLBConversationActivityMessageKey = @"message";
NSString *const CLBConversationActivityRoleKey = @"role";
NSString *const CLBConversationActivityActivityKey = @"activity";
NSString *const CLBConversationActivityTypeKey = @"type";
NSString *const CLBConversationActivityIdKey = @"_id";
NSString *const CLBConversationActivityDataKey = @"data";

@interface CLBConversationActivity ()

@property NSString *name;
@property NSString *conversationId;
@property NSString *avatarUrl;
@property NSDate *date;
@property BOOL isFromCurrentUser;
@property NSDate *appMakerLastRead;
@property NSString *appUserId;
@property NSString *type;

@end

@implementation CLBConversationActivity

- (instancetype) initWithRole:(NSString *)role
                         type:(NSString *)type
                         data:(NSDictionary *)data
                 conversation:(nullable NSDictionary *)conversation {
    self = [super init];

    if (self) {
        _role = role;
        _type = type;
        _data = data;
        _name = data[CLBConversationActivityDataNameKey];
        _avatarUrl = data[CLBConversationActivityDataAvatarUrlKey];
        _conversationId = conversation[CLBConversationActivityIdKey];
        _date = [NSDate date];
    }

    return self;
}

- (instancetype) initWithDictionary:(NSDictionary *)dictionary {
    NSDictionary *conversationDictionary = dictionary[CLBConversationActivityConversationKey];
    NSString *role = dictionary[CLBConversationActivityRoleKey];
    NSString *type = dictionary[CLBConversationActivityTypeKey];
    NSDictionary *data = dictionary[CLBConversationActivityDataKey];

    return [self initWithRole:role
                         type:type
                         data:data
                 conversation:conversationDictionary];
}

@end
