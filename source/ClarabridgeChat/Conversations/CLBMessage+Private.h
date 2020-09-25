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

// Serializes a message of type text, intended to be sent as part of create user/conversation requests
/// Only serializes the type and text properties, and returns nil if either of these are nil
- (nullable id)serializeTextForConversation;

- (BOOL)isEqualWithoutDate:(CLBMessage*)message;
- (BOOL)hasReplies;
- (BOOL)hasLocationRequest;
- (BOOL)hasCoordinates;

@property(weak, nonatomic) CLBConversation *conversation;

@property CLBMessageUploadStatus uploadStatus;
@property NSString *messageId;
@property NSString *userId;
@property NSString *role;
@property CLBCoordinates *coordinates;
@property CLBDisplaySettings *displaySettings;

@end
