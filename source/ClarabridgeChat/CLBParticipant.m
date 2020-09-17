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
NSString *const CLBParticipantAppUserId = @"appUserId";
NSString *const CLBParticipantUnreadCount = @"unreadCount";
NSString *const CLBParticipantLastRead = @"lastRead";

@interface CLBParticipant()

@property (readwrite) NSString *participantId;
@property (readwrite) NSString *appUserId;

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
        _appUserId = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:CLBParticipantAppUserId]);
        _unreadCount = CLBSanitizeNSNull([NSNumber numberWithInt:[[decoder decodeObjectOfClass:[NSString class] forKey:CLBParticipantUnreadCount] intValue]]);
        _lastRead = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSDate class] forKey:CLBParticipantLastRead]);
    }
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:self.participantId forKey:CLBParticipantId];
    [coder encodeObject:self.appUserId forKey:CLBParticipantAppUserId];
    [coder encodeObject:self.unreadCount forKey:CLBParticipantUnreadCount];
    [coder encodeObject:self.lastRead forKey:CLBParticipantLastRead];
}

- (void)deserialize:(NSDictionary *)object {
    _participantId = CLBSanitizeNSNull(object[CLBParticipantId]);
    _appUserId = CLBSanitizeNSNull(object[CLBParticipantAppUserId]);
    _unreadCount = [NSNumber numberWithInt:[CLBSanitizeNSNull(object[CLBParticipantUnreadCount]) intValue]];
    _lastRead = [NSDate dateWithTimeIntervalSince1970:[CLBSanitizeNSNull(object[CLBParticipantLastRead]) doubleValue]];
}

+ (NSDate *)getLastReadDateFromParticipants:(NSArray *)participants
                           currentAppUserId:(NSString *)appUserId
                           appMakerLastRead:(NSDate *)appMakerLastRead {
    NSDate *participantLastRead = appMakerLastRead;

    for (CLBParticipant *participant in participants) {
        //Ignore the current user, just check other participants
        if (![participant.appUserId isEqualToString:appUserId]) {
            //Check to see if any of the other participants have a lastRead date greater than appMaker's lastRead
            if ([participant.lastRead compare:participantLastRead] == NSOrderedDescending) {
                participantLastRead = participant.lastRead;
            }
        }
    }

    return participantLastRead;
}

+ (NSUInteger)getUnreadCountFromParticipants:(NSArray *)participants
                            currentAppUserId:(NSString *)appUserId {
    for (CLBParticipant *participant in participants) {
        if ([participant.appUserId isEqualToString:appUserId]) {
            return [participant.unreadCount intValue];
        }
    }

    return 0;
}

@end
