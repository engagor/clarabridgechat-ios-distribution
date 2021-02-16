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

- (instancetype _Nullable)initWithDictionary:(NSDictionary *_Nonnull)dictionary setIsFromCurrentUser:(BOOL)isFromCurrentUser;

// Serializes a message of type text, intended to be sent as part of create user/conversation requests
/// Only serializes the type and text properties, and returns nil if either of these are nil
- (nullable id)serializeTextForConversation;

- (BOOL)isEqualWithoutDate:(CLBMessage*_Nonnull)message;
- (BOOL)hasReplies;
- (BOOL)hasLocationRequest;
- (BOOL)hasCoordinates;

@property(weak, nonatomic) CLBConversation * _Nullable conversation;

@property CLBMessageUploadStatus uploadStatus;
@property NSString * _Nullable messageId;
@property NSString * _Nullable userId;
@property NSString * _Nullable role;
@property CLBCoordinates * _Nullable coordinates;
@property CLBDisplaySettings * _Nullable displaySettings;

@end
