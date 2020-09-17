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
@interface CLBParticipant (Private) < NSSecureCoding >

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (void)deserialize:(NSDictionary *)object;

+ (NSDate *)getLastReadDateFromParticipants:(NSArray *)participants
                           currentAppUserId:(NSString *)appUserId
                           appMakerLastRead:(NSDate *)appMakerLastRead;

+ (NSUInteger)getUnreadCountFromParticipants:(NSArray *)participants
                            currentAppUserId:(NSString *)appUserId;

@end
NS_ASSUME_NONNULL_END
