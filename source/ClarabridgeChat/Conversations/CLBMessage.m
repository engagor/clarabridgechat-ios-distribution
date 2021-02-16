//
//  CLBMessage.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBMessage+Private.h"
#import "CLBUser+Private.h"
#import "CLBUtility.h"
#import "CLBConversation+Private.h"
#import "CLBMessageAction+Private.h"
#import "CLBMessageItem+Private.h"
#import "CLBCoordinates+Private.h"
#import "CLBDisplaySettings+Private.h"
#import "CLBAuthorInfo.h"
#import "CLBParticipant.h"
#import "CLBParticipant+Private.h"

NSString* const CLBMessageUploadFailedNotification = @"CLBMessageUploadFailedNotification";
NSString* const CLBMessageUploadCompletedNotification = @"CLBMessageUploadCompletedNotification";
NSString* const CLBMessageTypeImage = @"image";
NSString* const CLBMessageTypeText = @"text";
NSString* const CLBMessageTypeLocation = @"location";
NSString* const CLBMessageTypeFile = @"file";
NSString* const CLBMessageTypeCarousel = @"carousel";
NSString* const CLBMessageTypeList = @"list";
long long const CLBMessageFileSizeLimit = 25 * 1000 * 1000;

static NSString* const kAppUserRole = @"appUser";
static NSString* const kBusinessRole = @"appMaker";

@interface CLBMessage()

@property CLBMessageUploadStatus uploadStatus;
@property NSString* messageId;
@property NSString* userId;
@property NSString* role;
@property(weak, nonatomic) CLBConversation* conversation;
@property NSArray* actions;
@property NSArray* items;
@property CLBDisplaySettings* displaySettings;
@property CLBCoordinates* coordinates;

@end

@implementation CLBMessage

@synthesize avatarUrl = _avatarUrl;

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        [self _deserialize:dictionary];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary setIsFromCurrentUser:(BOOL)isFromCurrentUser {
    self = [super init];
    if (self) {
        _isFromCurrentUser = isFromCurrentUser;
        [self _deserialize:dictionary];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _date = [NSDate date];
        _role = kAppUserRole;
        _uploadStatus = CLBMessageUploadStatusUnsent;
    }
    return self;
}

- (instancetype)initWithText:(NSString *)text {
    self = [self init];
    if (self) {
        _text = text;
        _type = CLBMessageTypeText;
    }
    return self;
}

- (instancetype)initWithText:(NSString *)text payload:(NSString *)payload metadata:(NSDictionary *)metadata {
    self = [self initWithText:text];

    if (self) {
        _metadata = metadata;
        _payload = payload;
    }

    return self;
}

- (instancetype)initWithCoordinates:(CLBCoordinates *)coordinates payload:(NSString *)payload metadata:(NSDictionary *)metadata {
    self = [self init];

    if (self) {
        _coordinates = coordinates;
        _metadata = metadata;
        _payload = payload;
        _type = CLBMessageTypeLocation;
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if(self){
        _messageId = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:@"messageId"]);
        _userId = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:@"authorId"]) ?: CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:@"userId"]);
        _text = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:@"text"]);
        _textFallback = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:@"textFallback"]);
        _displayName = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:@"name"]);
        _date = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSDate class] forKey:@"date"]);

        NSSet *classes = [NSSet setWithArray:@[[NSArray class], [CLBMessageAction class]]];
        _actions = CLBSanitizeNSNull([decoder decodeObjectOfClasses:classes forKey:@"actions"]);
        classes = [NSSet setWithArray:@[[NSArray class], [CLBMessageItem class]]];
        _items = CLBSanitizeNSNull([decoder decodeObjectOfClass:[CLBDisplaySettings class] forKey:@"items"]);

        _displaySettings = CLBSanitizeNSNull([decoder decodeObjectForKey:@"displaySettings"]);
        _avatarUrl = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:@"avatarUrl"]);
        _mediaUrl = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:@"mediaUrl"]);
        _mediaSize = CLBSanitizeNSNull([NSNumber numberWithLongLong:[decoder decodeInt64ForKey:@"mediaSize"]]);
        _role = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:@"role"]);
        _metadata = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSDictionary class] forKey:@"metadata"]);
        _payload = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:@"payload"]);
        _uploadStatus = [decoder decodeIntegerForKey:@"uploadStatus"];
        _type = CLBSanitizeNSNull([decoder decodeObjectOfClass:[NSString class] forKey:@"type"]);
        _coordinates = CLBSanitizeNSNull([decoder decodeObjectForKey:@"coordinates"]);

        if(!_role){
            NSString* userId = [decoder decodeObjectForKey:@"userId"];

            if(userId == nil || [decoder decodeBoolForKey:@"fromMe"]){
                _role = kAppUserRole;
            }else{
                _role = kBusinessRole;
            }
        }

        // For backwards compat
        NSInteger legacyStatus = [decoder decodeIntegerForKey:@"status"];
        if(_uploadStatus == 0 && legacyStatus > 0){
            if(legacyStatus >= 2){
                _uploadStatus = [self isFromCurrentUser] ? CLBMessageUploadStatusSent : CLBMessageUploadStatusNotUserMessage;
            }else{
                _uploadStatus = CLBMessageUploadStatusFailed;
            }
        }
    }
    return self;
}

- (BOOL)failed {
    return self.uploadStatus == CLBMessageUploadStatusFailed;
}

- (BOOL)sent {
    return self.uploadStatus != CLBMessageUploadStatusUnsent;
}

- (NSString *)imageAspectRatio {
    return self.displaySettings.imageAspectRatio;
}

- (BOOL)isRead {
    
    if (!self.date) {
        return NO;
    }
    
    BOOL readByBusiness = self.conversation.businessLastRead && [self.conversation.businessLastRead timeIntervalSinceDate:self.date] >= 0;
    BOOL readByParticipant =  [[self lastRead] timeIntervalSinceDate:self.date] >= 0;
    return self.isFromCurrentUser && (readByBusiness || readByParticipant);
}

- (NSDate *)lastRead {
    return [CLBParticipant getLastReadDateFromParticipants:self.conversation.participants
                                          currentUserId:self.conversation.user.userId
                                          businessLastRead:self.conversation.businessLastRead];
}

- (NSString*)avatarUrl {
    if(self.isFromCurrentUser){
        return nil;
    }else{
        return _avatarUrl;
    }
}

- (void)setAvatarUrl:(NSString *)avatarUrl {
    _avatarUrl = avatarUrl;
}

- (NSString*)remotePath {
    return [NSString stringWithFormat:@"/v2/apps/%@/conversations/%@/messages", self.conversation.appId, self.conversation.conversationId];
}

- (id)serialize {
    NSMutableDictionary *serialized = [kBusinessRole isEqualToString:self.role] ? [self serializeBusinessMessage] : [self serializeAppUserMessage];

    NSMutableDictionary *serializedMessage = serialized[@"message"];

    if (!serializedMessage) {
        return nil;
    }

    if (self.type) {
        [serializedMessage setObject:self.type forKey:@"type"];
    }

    if (self.text) {
        [serializedMessage setObject:self.text forKey:@"text"];
    }

    if (self.metadata) {
        [serializedMessage setObject:self.metadata forKey:@"metadata"];
    }

    if (self.payload) {
        [serializedMessage setObject:self.payload forKey:@"payload"];
    }

    if (self.coordinates) {
        [serializedMessage setObject:[self.coordinates serialize] forKey:@"coordinates"];
    }

    return serialized;
}

- (nullable id)serializeTextForConversation {

    if (!self.type || !self.text) {
        return nil;
    }

    NSMutableDictionary *serializedMessage = NSMutableDictionary.new;

    [serializedMessage setObject:self.type forKey:@"type"];

    [serializedMessage setObject:self.text forKey:@"text"];

    return serializedMessage;
}

- (id)serializeBusinessMessage {
    NSMutableDictionary *serializedMessage = [[NSMutableDictionary alloc] init];

    [serializedMessage setObject:kBusinessRole forKey:@"role"];

    if (self.messageId) {
        [serializedMessage setObject:self.messageId forKey:@"_id"];
    }

    if (self.userId) {
        [serializedMessage setObject:self.userId forKey:@"authorId"];
    }

    if (self.displayName) {
        [serializedMessage setObject:self.displayName forKey:@"name"];
    }

    if (self.avatarUrl) {
        [serializedMessage setObject:self.avatarUrl forKey:@"avatarUrl"];
    }

    if (self.date) {
        [serializedMessage setObject:@(self.date.timeIntervalSince1970) forKey:@"received"];
    }

    if (self.mediaUrl) {
        [serializedMessage setObject:self.mediaUrl forKey:@"mediaUrl"];
    }

    if (self.actions.count > 0) {
        NSMutableArray *actions = [[NSMutableArray alloc] initWithCapacity:self.actions.count];

        for (CLBMessageAction *action in self.actions) {
            [actions addObject:[action serialize]];
        }

        [serializedMessage setObject:actions forKey:@"actions"];
    }
    
    if (self.items.count > 0) {
        NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:self.items.count];
        
        for (CLBMessageItem *item in self.items) {
            [items addObject:[item serialize]];
        }
        
        [serializedMessage setObject:items forKey:@"items"];
    }
    
    if (self.displaySettings) {
        [serializedMessage setObject:[self.displaySettings serialize] forKey:@"displaySettings"];
    }

    return @{@"message": serializedMessage};
}

- (id)serializeAppUserMessage {
    if([CLBMessageTypeText isEqualToString:self.type] && !self.text) {
        return nil;
    }else if([CLBMessageTypeLocation isEqualToString:self.type] && ![self hasCoordinates]) {
        return nil;
    }

    NSMutableDictionary *serializedMessage = [[NSMutableDictionary alloc] init];

    return @{
             @"message": serializedMessage,
             @"author": [CLBAuthorInfo authorFieldForUser:self.conversation.user]
             };
}

- (void)deserialize:(NSDictionary *)object {
    [self _deserialize:object[@"messages"][0]];
    [self.conversation setUnreadCount:0];
}

- (void)_deserialize:(NSDictionary*)object {
    _messageId = CLBSanitizeNSNull(object[@"_id"]);
    _type = [self deserializeType:object];
    _mediaUrl = CLBSanitizeNSNull(object[@"mediaUrl"]);
    _mediaSize = [NSNumber numberWithLongLong:[CLBSanitizeNSNull(object[@"mediaSize"]) longLongValue]];
    _text = [self deserializeText:object];
    _textFallback = CLBSanitizeNSNull(object[@"textFallback"]);
    _userId = CLBSanitizeNSNull(object[@"authorId"]);
    _displayName = CLBSanitizeNSNull(object[@"name"]);
    _avatarUrl = CLBSanitizeNSNull(object[@"avatarUrl"]);
    _actions = [CLBMessageAction deserializeActions:CLBSanitizeNSNull(object[@"actions"])];
    _items = [self deserializeItems:CLBSanitizeNSNull(object[@"items"])];
    _displaySettings = [self deserializeDisplaySettings:CLBSanitizeNSNull(object[@"displaySettings"])];
    _date = [NSDate dateWithTimeIntervalSince1970:[CLBSanitizeNSNull(object[@"received"]) doubleValue]];
    _role = CLBSanitizeNSNull(object[@"role"]);
    _metadata = CLBSanitizeNSNull(object[@"metadata"]);
    _payload = CLBSanitizeNSNull(object[@"payload"]);
    _coordinates = [self deserializeCoordinates:CLBSanitizeNSNull(object[@"coordinates"])];
    _uploadStatus = [self isFromCurrentUser] ? CLBMessageUploadStatusSent : CLBMessageUploadStatusNotUserMessage;
}

- (NSString *)deserializeType:(NSDictionary*)object {
    NSString *type = CLBSanitizeNSNull(object[@"type"]);

    if (!type) {
        NSString *mediaUrl = CLBSanitizeNSNull(object[@"mediaUrl"]);
        type = mediaUrl ? CLBMessageTypeImage : CLBMessageTypeText;
    }

    return type;
}

- (NSString *)deserializeText:(NSDictionary*)object {
    NSString *text = CLBSanitizeNSNull(object[@"text"]);
    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if ([@[CLBMessageTypeImage, CLBMessageTypeFile] containsObject:self.type]) {
        if (trimmed.length == 0 || [trimmed isEqualToString:CLBSanitizeNSNull(object[@"mediaUrl"])]) {
            text = nil;
        }
    }

    return text;
}

- (NSArray*)deserializeItems:(NSArray*)itemObjects {
    if(!itemObjects || itemObjects.count == 0){
        return nil;
    }

    NSMutableArray *items = [NSMutableArray array];
    
    for(NSDictionary *itemDictionary in itemObjects){
        [items addObject:[[CLBMessageItem alloc] initWithDictionary:itemDictionary]];
    }
    
    return [items copy];
}

- (CLBCoordinates *)deserializeCoordinates:(NSDictionary *)object {
    if (!object) {
        return nil;
    }

    CLBCoordinates *coordinates = [[CLBCoordinates alloc] init];
    [coordinates deserialize:object];

    return coordinates;
}

- (CLBDisplaySettings *)deserializeDisplaySettings:(NSDictionary *)object {
    if (!object) {
        return nil;
    }
    
    return [[CLBDisplaySettings alloc] initWithDictionary:object];
}

- (BOOL)isEqualToMessage:(CLBMessage*)message withDate:(BOOL)withDate{
    if(!message){
        return NO;
    }

    if(self.messageId != nil && message.messageId != nil){
        return [self.messageId isEqualToString:message.messageId];
    }

    BOOL haveSameText = self.text == message.text || [self.text isEqualToString:message.text];
    BOOL haveSameAuthor;

    if(self.userId == nil || message.userId == nil){
        haveSameAuthor = self.isFromCurrentUser == message.isFromCurrentUser;
    }else{
        haveSameAuthor = [self.userId isEqualToString:message.userId];
    }

    BOOL haveSameDate = self.date == message.date || ABS([self.date timeIntervalSinceDate:message.date]) < 0.001;
    if(!withDate){
        haveSameDate = YES;
    }

    return haveSameText && haveSameAuthor && haveSameDate;
}

- (BOOL)isEqualToMessage:(CLBMessage*)message {
    return [self isEqualToMessage:message withDate:YES];
}

- (BOOL)isEqualWithoutDate:(CLBMessage*)message {
    return [self isEqualToMessage:message withDate:NO];
}

- (BOOL)hasReplies {
    for (CLBMessageAction *action in self.actions) {
        if ([CLBMessageActionTypeReply isEqualToString:action.type]) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)hasLocationRequest {
    for (CLBMessageAction *action in self.actions) {
        if ([CLBMessageActionTypeLocationRequest isEqualToString:action.type]) {
            return YES;
        }
    }

    return NO;
}

- (UIImage*)image {
    return nil;
}

- (double)progress {
    return 0;
}

- (BOOL)hasCoordinates {
    return self.coordinates && self.coordinates.latitude != nil && self.coordinates.longitude != nil;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[CLBMessage class]]) {
        return NO;
    }

    return [self isEqualToMessage:(CLBMessage *)object];
}

- (NSUInteger)hash {
    return [self.text hash] ^ [self.userId hash] ^ [self.date hash];
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.messageId forKey:@"messageId"];
    [coder encodeObject:self.userId forKey:@"authorId"];
    [coder encodeObject:self.text forKey:@"text"];
    [coder encodeObject:self.textFallback forKey:@"textFallback"];
    [coder encodeObject:self.displayName forKey:@"name"];
    [coder encodeObject:self.date forKey:@"date"];
    [coder encodeObject:self.actions forKey:@"actions"];
    [coder encodeObject:self.items forKey:@"items"];
    [coder encodeObject:self.mediaUrl forKey:@"mediaUrl"];
    [coder encodeInt64:[self.mediaSize longLongValue] forKey:@"mediaSize"];
    [coder encodeObject:self.role forKey:@"role"];
    [coder encodeObject:self.metadata forKey:@"metadata"];
    [coder encodeObject:self.payload forKey:@"payload"];
    [coder encodeObject:self.avatarUrl forKey:@"avatarUrl"];
    [coder encodeInteger:self.uploadStatus forKey:@"uploadStatus"];
    [coder encodeObject:self.type forKey:@"type"];
    [coder encodeObject:self.coordinates forKey:@"coordinates"];
    [coder encodeObject:self.displaySettings forKey:@"displaySettings"];
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone {
    CLBMessage *message = [[CLBMessage allocWithZone:zone] init];

    message.messageId = [self.messageId copy];
    message.userId = [self.userId copy];
    message.text = [self.text copy];
    message.textFallback = [self.textFallback copy];
    message.displayName = [self.displayName copy];
    message.date = [self.date copy];
    message.actions = [[NSArray alloc] initWithArray:self.actions copyItems:YES];
    message.items = [[NSArray alloc] initWithArray:self.items copyItems:YES];
    message.mediaUrl = [self.mediaUrl copy];
    message.mediaSize = [self.mediaSize copy];
    message.role = [self.role copy];
    message.metadata = [self.metadata copy];
    message.payload = [self.payload copy];
    message.avatarUrl = [self.avatarUrl copy];
    message.uploadStatus = self.uploadStatus;
    message.type = [self.type copy];
    message.coordinates = [self.coordinates copy];
    message.conversation = self.conversation;
    message.displaySettings = [self.displaySettings copy];

    return message;
}

@end
