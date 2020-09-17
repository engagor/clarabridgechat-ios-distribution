//
//  CLBMessage+Private.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ClarabridgeChat/CLBMessage.h>
#import "CLBSOMessage.h"
#import "CLBRemoteObject.h"
@class CLBUser;
@class CLBConversation;

extern long long const CLBMessageFileSizeLimit;

@interface CLBMessage(Private) < CLBSOMessage, CLBRemoteObject, NSCoding, NSCopying >

- (instancetype)initWithDictionary:(NSDictionary *)dictionary setIsFromCurrentUser:(BOOL)isFromCurrentUser;

- (BOOL)isEqualWithoutDate:(CLBMessage*)message;
- (BOOL)hasReplies;
- (BOOL)hasLocationRequest;
- (BOOL)hasCoordinates;

@property(weak, nonatomic) CLBConversation *conversation;

@property CLBMessageUploadStatus uploadStatus;
@property NSString *messageId;
@property NSString *authorId;
@property NSString *role;
@property CLBCoordinates *coordinates;
@property CLBDisplaySettings *displaySettings;

@end
