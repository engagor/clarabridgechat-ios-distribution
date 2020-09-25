//
//  CLBParticipant+Private.h
//  ClarabridgeChat
//
//  Created by Alan O'Connor on 27/03/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClarabridgeChat/CLBParticipant.h"

NS_ASSUME_NONNULL_BEGIN
@interface CLBParticipant (Private) < NSSecureCoding, NSCopying >

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (void)deserialize:(NSDictionary *)object;

+ (NSDate *)getLastReadDateFromParticipants:(NSArray *)participants
                           currentUserId:(NSString *)userId
                           businessLastRead:(NSDate *)businessLastRead;

+ (NSUInteger)getUnreadCountFromParticipants:(NSArray *)participants
                            currentUserId:(NSString *)userId;

@end
NS_ASSUME_NONNULL_END
