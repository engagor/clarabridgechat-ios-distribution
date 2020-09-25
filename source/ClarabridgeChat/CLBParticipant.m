//
//  CLBParticipant.m
//  ClarabridgeChat
//
//  Created by Shona Nunez on 19/02/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBParticipant.h"
#import "CLBUtility.h"
#import "CLBConversation+Private.h"
#import "CLBUser+Private.h"

NSString *const CLBParticipantId = @"_id";
NSString *const CLBParticipantUserId = @"appUserId";
NSString *const CLBParticipantUnreadCount = @"unreadCount";
NSString *const CLBParticipantLastRead = @"lastRead";

@interface CLBParticipant()

@property (readwrite) NSString *participantId;
@property (readwrite) NSString *userId;

@end

@implementation CLBParticipant

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        [self deserialize:dictionary];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        _participantId = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:CLBParticipantId]);
        _userId = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:CLBParticipantUserId]);
        _unreadCount = CLBSanitizeNSNull([NSNumber numberWithInt:[[decoder decodeObjectOfClass:[NSString class] forKey:CLBParticipantUnreadCount] intValue]]);
        _lastRead = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSDate class] forKey:CLBParticipantLastRead]);
    }
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:self.participantId forKey:CLBParticipantId];
    [coder encodeObject:self.userId forKey:CLBParticipantUserId];
    [coder encodeObject:self.unreadCount forKey:CLBParticipantUnreadCount];
    [coder encodeObject:self.lastRead forKey:CLBParticipantLastRead];
}

- (id)copyWithZone:(NSZone *)zone {
    CLBParticipant *participant = [[[self class] alloc] init];
    if (participant) {
        participant.participantId = _participantId.copy;
        participant.userId = _userId.copy;
        participant.unreadCount = _unreadCount.copy;
        participant.lastRead = _lastRead.copy;
    }
    return participant;
}

- (void)deserialize:(NSDictionary *)object {
    _participantId = CLBSanitizeNSNull(object[CLBParticipantId]);
    _userId = CLBSanitizeNSNull(object[CLBParticipantUserId]);
    _unreadCount = [NSNumber numberWithInt:[CLBSanitizeNSNull(object[CLBParticipantUnreadCount]) intValue]];
    _lastRead = [NSDate dateWithTimeIntervalSince1970:[CLBSanitizeNSNull(object[CLBParticipantLastRead]) doubleValue]];
}

+ (NSDate *)getLastReadDateFromParticipants:(NSArray *)participants
                           currentUserId:(NSString *)userId
                           businessLastRead:(NSDate *)businessLastRead {
    NSDate *participantLastRead = businessLastRead;

    for (CLBParticipant *participant in participants) {
        //Ignore the current user, just check other participants
        if (![participant.userId isEqualToString:userId]) {
            //Check to see if any of the other participants have a lastRead date greater than business's lastRead
            if ([participant.lastRead compare:participantLastRead] == NSOrderedDescending) {
                participantLastRead = participant.lastRead;
            }
        }
    }

    return participantLastRead;
}

+ (NSUInteger)getUnreadCountFromParticipants:(NSArray *)participants
                            currentUserId:(NSString *)userId {
    for (CLBParticipant *participant in participants) {
        if ([participant.userId isEqualToString:userId]) {
            return [participant.unreadCount intValue];
        }
    }

    return 0;
}

@end
