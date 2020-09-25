//
//  CLBConversation.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBConversation.h"
#import "CLBConversation+Private.h"
#import "CLBMessage+Private.h"
#import "CLBMessageAction+Private.h"
#import "CLBUtility.h"
#import "ClarabridgeChat+Private.h"
#import "CLBUser+Private.h"
#import "CLBConversationActivity+Private.h"
#import "CLBSettings+Private.h"
#import "CLBPersistence.h"
#import "CLBFailedUpload.h"
#import "CLBApiClient.h"
#import "CLBDependencyManager.h"
#import "CLBConversationPersistence.h"
#import "CLBParticipant.h"
#import "CLBParticipant+Private.h"

NSString *const CLBConversationDidMarkAllAsReadNotification = @"CLBConversationDidMarkAllAsReadNotification";
NSString *const CLBConversationDidRequestPreviousMessagesNotification = @"CLBConversationDidRequestPreviousMessagesNotification";
NSString *const CLBConversationDidReceivePreviousMessagesNotification = @"CLBConversationDidReceivePreviousMessagesNotification";
NSString *const CLBConversationUnreadCountDidChangeNotification = @"CLBConversationUnreadCountDidChangeNotification";
NSString *const CLBConversationDidReceiveMessagesNotification = @"CLBConversationDidReceiveMessagesNotification";
NSString *const CLBConversationDidReceiveActivityNotification = @"CLBConversationDidReceiveActivityNotification";
NSString *const CLBConversationNewMessagesKey = @"CLBConversationNewMessagesKey";
NSString *const CLBConversationPreviousMessagesKey = @"CLBConversationPreviousMessagesKey";
NSString *const CLBConversationImageUploadDidStartNotification = @"CLBConversationImageUploadDidStartNotification";
NSString *const CLBConversationImageUploadProgressDidChangeNotification = @"CLBConversationImageUploadProgressDidChangeNotification";
NSString *const CLBConversationImageUploadCompletedNotification = @"CLBConversationImageUploadCompletedNotification";
NSString *const CLBConversationFileUploadDidStartNotification = @"CLBConversationFileUploadDidStartNotification";
NSString *const CLBConversationFileUploadProgressDidChangeNotification = @"CLBConversationFileUploadProgressDidChangeNotification";
NSString *const CLBConversationFileUploadCompletedNotification = @"CLBConversationFileUploadCompletedNotification";
NSString *const CLBConversationTypingDidStartNotification = @"CLBConversationTypingDidStartNotification";
NSString *const CLBConversationTypingDidStopNotification = @"CLBConversationTypingDidStopNotification";
NSString *const CLBConversationImageKey = @"image";
NSString *const CLBConversationFileKey = @"file";
NSString *const CLBConversationErrorKey = @"error";
NSString *const CLBConversationMessageKey = @"message";
NSString *const CLBConversationProgressKey = @"progress";
NSString *const CLBConversationActivityKey = @"activity";

NSString *const CLBPendingUploadFileKey = @"fileLocation";
NSString *const CLBPendingUploadMessageKey = @"message";
NSString *const CLBPendingUploadImageKey = @"image";
NSString *const CLBPendingUploadCompletionBlockKey = @"completionBlock";
NSString *const CLBPendingUploadErrorKey = @"error";

static const int kTypingEventTimeoutSeconds = 10;
static const int kTypingStopBufferSeconds = 1;

@interface CLBConversation()

@property NSMutableArray *internalMessages;
@property NSMutableArray *internalParticipants;
@property NSString *conversationId;
@property CLBUser *user;
@property NSUInteger unreadCount;
@property NSDictionary *metadata;
@property BOOL hasPreviousMessages;
@property BOOL hasPagedBack;
@property NSDate *lastTypingStartEvent;
@property NSDate *lastUploadedTypingStartEvent;
@property NSTimer *typingTimeoutTimer;
@property NSDate *businessLastRead;
@property NSMutableDictionary *pendingFileUploads;
@property NSMutableDictionary *failedFileUploads;
@property (nonatomic, weak) id<CLBConversationPersistence> persistence;
@property NSString *appId;
@property NSDate *lastUpdatedAt;
@property NSString *displayName;
@property NSString *conversationDescription;
@property NSString *iconUrl;
@property NSArray *participants;

@end

@implementation CLBConversation
@synthesize unreadCount = _unreadCount;

+ (BOOL)supportsSecureCoding {
    return YES;
}

+ (instancetype)conversationWithAppId:(NSString *)appId user:(CLBUser *)user settings:(CLBSettings *)settings {
    return [[CLBConversation alloc] initWithAppId:appId user:user];
}

+ (NSString *)filePathForAppId:(NSString *)appId deviceId:(NSString *)deviceId externalId:(NSString *)externalId {
    if (!appId || !deviceId){
        return nil;
    }

    NSError *error;
    NSURL *systemDir = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory
                                                              inDomain:NSUserDomainMask
                                                     appropriateForURL:nil
                                                                create:YES
                                                                 error:&error];
    if (systemDir){
        NSURL *folder = [systemDir URLByAppendingPathComponent:appId];

        [[NSFileManager defaultManager] createDirectoryAtPath:[folder path] withIntermediateDirectories:YES attributes:nil error:nil];

        NSString* filename;
        if (externalId) {
            filename = [NSString stringWithFormat:@"%@:%@", deviceId, externalId];
        } else {
            filename = deviceId;
        }

        return [[[folder URLByAppendingPathComponent:filename] URLByAppendingPathExtension:@"conversation"] path];
    } else {
        // Should technically never happen
        return nil;
    }
}

- (instancetype)init {
    return [self initWithAppId:nil user:nil];
}

- (instancetype)initWithAppId:(NSString *)appId user:(CLBUser *)user {
    self = [super init];
    if (self) {
        _internalMessages = [NSMutableArray array];
        _internalParticipants = [NSMutableArray array];
        _appId = appId;
        _user = user;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        _conversationId = [decoder decodeObjectOfClass:[NSString class] forKey:@"conversationId"];
        _unreadCount = [decoder decodeIntegerForKey:@"unreadCount"];
        _metadata = [decoder decodeObjectOfClass:[NSDictionary class] forKey:@"metadata"];
        _hasPreviousMessages = [decoder decodeBoolForKey:@"hasPreviousMessages"];
        _businessLastRead = [decoder decodeObjectOfClass:[NSDate class] forKey:@"appMakerLastRead"];
        _displayName = [decoder decodeObjectOfClass:[NSString class] forKey:@"displayName"];
        _conversationDescription = [decoder decodeObjectOfClass:[NSString class] forKey:@"description"];
        _iconUrl = [decoder decodeObjectOfClass:[NSString class] forKey:@"iconUrl"];
        _lastUpdatedAt = [decoder decodeObjectOfClass:[NSDate class] forKey:@"lastUpdatedAt"];

        NSSet *messagesSet = [NSSet setWithArray:@[[NSArray class], [CLBMessage class]]];
        _internalMessages = [decoder decodeObjectOfClasses:messagesSet forKey:@"messages"];
        NSSet *participantsSet = [NSSet setWithArray:@[[NSArray class], [CLBParticipant class]]];
        _internalParticipants = [decoder decodeObjectOfClasses:participantsSet forKey:@"participants"];
    }
    return self;
}

- (void)dealloc {
    [_typingTimeoutTimer invalidate];
}

- (void)saveToDisk {
    if (self.persistence) {
        [self.persistence storeConversation:self];
    }
}

- (void)removeFromDisk {
    if (self.persistence) {
        [self.persistence removeConversation:self];
    }
}

- (instancetype)readOrCreateConversationForId:(NSString *)conversationId {
    CLBConversation *conversation = [self.persistence readConversation:conversationId];

    if (!conversation) {
        conversation = [[CLBConversation alloc] initWithAppId:self.appId user:self.user];
        conversation.conversationId = conversationId;
    }

    return conversation;
}

- (void)handleNewOrChangedConversation:(NSDictionary *)object {
    NSDictionary *conversation = object[@"conversation"];

    if (self.persistence) {
        CLBConversation *changedConversation = [self readOrCreateConversationForId:conversation[@"_id"]];
        changedConversation.businessLastRead = [NSDate dateWithTimeIntervalSince1970:[conversation[@"appMakerLastRead"] doubleValue]];
        changedConversation.hasPreviousMessages = object[@"previous"] == nil ? [object[@"hasPrevious"] boolValue] : [object[@"previous"] boolValue];
        changedConversation.hasPagedBack = NO;
        changedConversation.pendingFileUploads = nil;
        changedConversation.failedFileUploads = nil;
        changedConversation.typingTimeoutTimer = nil;
        changedConversation.lastTypingStartEvent = nil;
        changedConversation.lastUploadedTypingStartEvent = nil;
        changedConversation.appId = self.appId;
        changedConversation.user = self.user;
        changedConversation.displayName = conversation[@"displayName"];
        changedConversation.conversationDescription = conversation[@"description"];
        changedConversation.iconUrl = conversation[@"iconUrl"];
        [changedConversation updateLastUpdatedAt:conversation];

        changedConversation.internalMessages = [self createMessagesFromObject:object forConversation:changedConversation];
        changedConversation.internalParticipants = [self createParticipantsFromObject:object];
        changedConversation.unreadCount = [CLBParticipant getUnreadCountFromParticipants:changedConversation.internalParticipants
                                                                        currentUserId:changedConversation.user.userId];

        [self.persistence storeConversation:changedConversation];
        [self.persistence conversationHasChanged:changedConversation];
    }
}

- (NSMutableArray<CLBMessage *> *)createMessagesFromObject:(NSDictionary *)object forConversation:(CLBConversation *)conversation {
    NSMutableArray<CLBMessage *> *messages = [NSMutableArray array];

    for (NSDictionary *dictionary in object[@"messages"]){
        BOOL isFromCurrentUser = [self.user.userId isEqualToString:dictionary[@"authorId"]];
        CLBMessage *incomingMessage = [[CLBMessage alloc] initWithDictionary:dictionary setIsFromCurrentUser:isFromCurrentUser];
        incomingMessage.conversation = conversation;
        [messages addObject:incomingMessage];
    }

    return messages;
}

- (NSMutableArray<CLBParticipant *> *)createParticipantsFromObject:(NSDictionary *)object {
    NSDictionary *participantsDictionary = object[@"participants"] == nil ? object[@"conversation"][@"participants"] : object[@"participants"];

    NSMutableArray<CLBParticipant *> *participants = [NSMutableArray array];

    for (NSDictionary *dictionary in participantsDictionary) {
        CLBParticipant *participant = [[CLBParticipant alloc] initWithDictionary:dictionary];
        [participants addObject:participant];
    }

    return participants;
}

- (void)deserialize:(NSDictionary *)object {
     NSDictionary *conversationObject = object[@"conversation"];
    NSDictionary *conversation = object;

    if (conversationObject != nil) { //conversationObject will be nil for conversationList on login
        conversation = conversationObject;
    }

    NSString* conversationId = conversation[@"_id"];

    if (![self.conversationId isEqualToString:conversationId]) {
        if (self.conversationId && (conversationId && conversationId.length > 0)) {
            // We are loading a different conversation, reset all local state to the new information
            [self handleNewOrChangedConversation:object];
            return;
        } else if (self.conversationId && (!conversationId || conversationId.length == 0)) {
            // This happens because the /messages endpoint no longer has conversation in its payload
            // Assume this response is part of the same conversation
            conversationId = self.conversationId;
        } else {
            // This is the first conversation fetch, simply assign the ID and proceed as normal
            self.conversationId = conversationId;
        }
    }

    self.displayName = conversation[@"displayName"];
    self.conversationDescription = conversation[@"description"];
    self.iconUrl = conversation[@"iconUrl"];
    self.metadata = CLBSanitizeNSNull(conversation[@"metadata"]);

    self.iconUrl = conversation[@"iconUrl"];

    if (object[@"participants"] != nil || object[@"conversation"][@"participants"] != nil) {
        [self setParticipants:[self createParticipantsFromObject:object]];
    }

    self.businessLastRead = [NSDate dateWithTimeIntervalSince1970:[conversation[@"appMakerLastRead"] doubleValue]];
    [self updateLastUpdatedAt: object];

    NSArray<NSDictionary*>* serverMessages = object[@"messages"];

    if (serverMessages == nil) {
        // This is a POST /messages response, nothing else to do
        return;
    }

    NSString *hasPreviousValue = object[@"previous"] == nil ? object[@"hasPrevious"] : object[@"previous"];
    NSString *hasNextValue = object[@"next"] == nil ? object[@"hasNext"] : object[@"next"];

    if (conversationObject == nil && hasPreviousValue == nil && hasNextValue == nil) {
        //This is a conversation with one message that comes from the /conversations response
        NSMutableArray<CLBMessage *> *messages = [NSMutableArray array];

        for(NSDictionary *dictionary in serverMessages){
            BOOL isFromCurrentUser = [self.user.userId isEqualToString:dictionary[@"authorId"]];
            CLBMessage *incomingMessage = [[CLBMessage alloc] initWithDictionary:dictionary setIsFromCurrentUser:isFromCurrentUser];
            incomingMessage.conversation = self;
            if(![messages containsObject:incomingMessage]) {
                [messages addObject:incomingMessage];
            }
        }

        if (messages.count > 0) { //For a new user this means the response is from /appusers, so no messages will exist yet (UI issue)
            [self setMessages:messages];
        }

        // If there are participants, determine the unread count of the current appUser.
        if (self.participants && self.participants.count > 0) {
            self.unreadCount = [CLBParticipant getUnreadCountFromParticipants:self.participants
                                                             currentUserId:self.user.userId];
        }

        [self saveToDisk];

        //This shouldn't go through the rest of the logic below
        return;
    }

    //This code is called only when the API response is from /conversation/id or /messages
    BOOL hasPreviousMessages = [hasPreviousValue boolValue];
    BOOL hasNext = [hasNextValue boolValue];
    BOOL areLatestMessages = !hasNext;

    NSArray<CLBMessage *> *messagesToNotify;
    NSMutableArray<CLBMessage *> *previousMessagesToNotify = [[NSMutableArray alloc] init];

    BOOL shouldClearCache;

    if (areLatestMessages) {
        if (self.hasPagedBack) {
            if (hasPreviousMessages) {
                // Everything is as we think it is, don't clear the cache
                shouldClearCache = NO;
            } else {
                // There used to be multiple pages, but now there aren't. Messages were deleted
                shouldClearCache = YES;
            }
        } else {
            // You haven't paged back in the history yet, take the server messages as the truth
            shouldClearCache = YES;
        }
    } else {
        // We are paging back in the history, keep the cache intact
        shouldClearCache = NO;
    }

    @synchronized (self) {
        NSMutableArray<CLBMessage *> *messages = shouldClearCache ? [NSMutableArray array] : [self.internalMessages mutableCopy];

        for(NSDictionary* dictionary in serverMessages){
            BOOL isFromCurrentUser = [self.user.userId isEqualToString:dictionary[@"authorId"]];
            CLBMessage* incomingMessage = [[CLBMessage alloc] initWithDictionary:dictionary setIsFromCurrentUser:isFromCurrentUser];
            incomingMessage.conversation = self;
            if(![messages containsObject:incomingMessage]) {
                [messages addObject:incomingMessage];
            }
            if(!areLatestMessages) {
                [previousMessagesToNotify addObject:incomingMessage];
            }
        }

        if (shouldClearCache) {
            [self addSendingOrFailedMessagesToMessages:messages];
            self.hasPreviousMessages = hasPreviousMessages;
        }

        [messages sortUsingComparator:^NSComparisonResult(CLBMessage* obj1, CLBMessage* obj2) {
            return [obj1.date compare:obj2.date];
        }];

        NSArray* oldMessages = self.internalMessages;

        if ([oldMessages isEqualToArray:messages]) {
            if (shouldClearCache) {
                self.internalMessages = messages;
            }
            // Messages are the same, update the unread count and return
            NSUInteger previousUnreadCount = self.unreadCount;
            self.unreadCount = [CLBParticipant getUnreadCountFromParticipants:self.participants
                                                             currentUserId:self.user.userId];

            [self updatePendingMessages];
            if (shouldClearCache || previousUnreadCount != self.unreadCount) {
                [self saveToDisk];
            }

            return;
        }

        if (shouldClearCache) {
            self.hasPagedBack = NO;
        }

        self.hasPreviousMessages = hasPreviousMessages;

        if (!areLatestMessages) {
            self.hasPagedBack = YES;
        }

        NSUInteger previousUnreadCount = self.unreadCount;
        self.unreadCount = [CLBParticipant getUnreadCountFromParticipants:self.participants
                                                         currentUserId:self.user.userId];

        [self setMessages:messages];

        if (self.unreadCount > 0 && (self.unreadCount != previousUnreadCount) && areLatestMessages) {
            NSUInteger numberToNotify;

            if(self.unreadCount <= previousUnreadCount){
                numberToNotify = self.unreadCount;
            }else{
                numberToNotify = self.unreadCount - previousUnreadCount;
            }

            NSArray* businessMessages = [messages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"uploadStatus == %ld", CLBMessageUploadStatusNotUserMessage]];
            messagesToNotify = [businessMessages subarrayWithRange:NSMakeRange(businessMessages.count - numberToNotify, numberToNotify)];
        }
    }
    
    [self updatePendingMessages];

    if (messagesToNotify) {
        [self notifyMessagesReceived:messagesToNotify];
    }

    if (previousMessagesToNotify.count > 0) {
        [self notifyPreviousMessagesReceived:previousMessagesToNotify];
    }
}

- (void)updateLastUpdatedAt:(NSDictionary *)object {
    NSNumber *lastUpdatedAt = object[@"lastUpdatedAt"];
    if (lastUpdatedAt != NULL) {
        self.lastUpdatedAt = [[NSDate alloc] initWithTimeIntervalSince1970: lastUpdatedAt.doubleValue];
    }
}

- (void)updatePendingMessages {
    if (!self.pendingFileUploads) {
        return;
    }
    
    NSArray *appUserMessages = [self.internalMessages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"uploadStatus == %ld", CLBMessageUploadStatusSent]];
    
    for (CLBMessage *appUserMessage in appUserMessages) {
        [self checkAndNotifyPendingUpload:appUserMessage.messageId message:appUserMessage error:nil];
    }
    
    NSDictionary *remainingPendingUploads = [self.pendingFileUploads copy];
    NSError *genericError = [NSError errorWithDomain:CLBErrorDomainIdentifier code:400 userInfo:nil];
    
    for (NSString *messageId in remainingPendingUploads) {
        [self checkAndNotifyPendingUpload:messageId message:nil error:genericError];
    }
}

- (void)clearExpiredMessages {
    NSMutableArray *messages = _internalMessages;
    if (messages.count > 50) {
        for (NSInteger i = messages.count - 51; i >= 0; i--) {
            CLBMessage *message = messages[i];
            if (message.uploadStatus == CLBMessageUploadStatusFailed || message.uploadStatus == CLBMessageUploadStatusUnsent) {
                [messages removeObjectAtIndex:i];
            }
        }
    }
}

- (NSArray *)getSendingOrFailedMessages {
    return [self.internalMessages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"uploadStatus == %ld OR uploadStatus == %ld", CLBMessageUploadStatusUnsent, CLBMessageUploadStatusFailed]];
}

- (void)addSendingOrFailedMessagesToMessages:(NSMutableArray<CLBMessage *> *) messages {
    NSArray* sendingOrFailedMessages = [self getSendingOrFailedMessages];

    for (CLBMessage* message in sendingOrFailedMessages) {
        if (![messages containsObject:message]) {
            [messages addObject:message];
        }
    }
}

- (void)notifyMessagesReceived:(NSArray*)messages {
    CLBEnsureMainThread(^{
        if ([self.delegate respondsToSelector:@selector(conversation:didReceiveMessages:)]) {
            [self.delegate conversation:self didReceiveMessages:messages];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationDidReceiveMessagesNotification
                                                            object:self
                                                          userInfo:@{ CLBConversationNewMessagesKey : messages }];
    });
}

- (void)notifyPreviousMessagesReceived:(NSArray *)messages {
    CLBEnsureMainThread(^{
        if ([self.delegate respondsToSelector:@selector(conversation:didReceivePreviousMessages:)]) {
            [self.delegate conversation:self didReceivePreviousMessages:messages];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationDidReceivePreviousMessagesNotification
                                                            object:self
                                                          userInfo:@{ CLBConversationPreviousMessagesKey : messages }];
    });
}

- (id)serialize {
    return nil;
}

- (NSString *)remotePath {
    return [NSString stringWithFormat:@"/v2/apps/%@/conversations/%@", self.appId, self.conversationId];
}

- (NSString *)messagesRemotePath {
    return [NSString stringWithFormat:@"/v2/apps/%@/conversations/%@/messages", self.appId, self.conversationId];
}

- (void)notifyActivity:(CLBConversationActivity *)activity {
    CLBEnsureMainThread(^{
        if ([self.delegate respondsToSelector:@selector(conversation:didReceiveActivity:)]) {
            [self.delegate conversation:self didReceiveActivity:activity];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationDidReceiveActivityNotification
                                                            object:self
                                                          userInfo:@{ CLBConversationActivityKey : activity }];
    });
}

- (void)setMessages:(NSArray *)messages {
    @synchronized(self){
        self.internalMessages = [messages mutableCopy];
        [self saveToDisk];
    }
}

- (NSArray*)messages {
    @synchronized(self){
        return [self.internalMessages copy];
    }
}

- (void)setParticipants:(NSArray *)participants {
    @synchronized(self){
        self.internalParticipants = [participants mutableCopy];
        [self saveToDisk];
    }
}

- (NSArray *)participants {
    @synchronized (self) {
        return [self.internalParticipants copy];
    }
}

- (long long)sizeForFile:(NSURL *)file {
    return CLBSizeForFile(file);
}

- (void)sendFile:(NSURL *)fileLocation
    withProgress:(CLBFileUploadProgressBlock)progressBlock
      completion:(CLBFileUploadCompletionBlock)completionBlock {
    NSString *errorMessage;
    
    BOOL isDirectory;
    
    if (!fileLocation) {
        errorMessage = @"Ignoring a file upload with nil location";
    } else if (![[NSFileManager defaultManager] fileExistsAtPath:fileLocation.path isDirectory:&isDirectory]) {
        errorMessage = @"Ignoring a file that doesn't exist";
    } else if (isDirectory) {
        errorMessage = @"Ignoring file upload for directory";
    } else {
        long long fileSize = [self sizeForFile:fileLocation];
        
        if (fileSize > CLBMessageFileSizeLimit) {
            errorMessage = @"Ignoring file upload for files bigger than 25 MB";
        }
    }
    
    if (errorMessage) {
        NSLog(@"<CLARABRIDGECHAT::WARNING> %@", errorMessage);
        
        NSDictionary *userInfo = @{CLBErrorDescriptionIdentifier: errorMessage};
        NSError *error = [NSError errorWithDomain:CLBErrorDomainIdentifier code:400 userInfo:userInfo];
        
        [self notifyFileUploadCompleteForFile:fileLocation message:nil error:error completion:completionBlock];
        return;
    }
    
    NSDictionary* metadata;
    if ([self.delegate respondsToSelector:@selector(conversation:willSendMessage:)]) {
        CLBMessage* fakeMessage = [[CLBMessage alloc] init];
        fakeMessage.type = CLBMessageTypeFile;
        
        CLBMessage* modifiedMessage = [self.delegate conversation:self willSendMessage:fakeMessage];
        if(modifiedMessage.metadata) {
            metadata = modifiedMessage.metadata;
        }
    }
    
    CLBEnsureMainThread(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationFileUploadDidStartNotification
                                                            object:self
                                                          userInfo:@{
                                                                     CLBConversationFileKey: fileLocation
                                                                     }];
    });
    
    [self cancelTyping];
    
    if (self.conversationId == nil) {
        [ClarabridgeChat startConversationWithIntent:@"message:appUser" completionHandler:^(NSError *error, NSDictionary *userInfo) {
            if (!error) {
                [self sendFile:fileLocation withMetadata:metadata withProgress:progressBlock completion:completionBlock];
            } else {
                [self notifyFileUploadCompleteForFile:fileLocation message:nil error:error completion:completionBlock];
            }
        }];
        
        return;
    }
    
    [self sendFile:fileLocation withMetadata:metadata withProgress:progressBlock completion:completionBlock];
}

- (void)sendFile:(NSURL *)fileLocation
    withMetadata:(NSDictionary*)metadata
    withProgress:(CLBFileUploadProgressBlock)progressBlock
      completion:(CLBFileUploadCompletionBlock)completionBlock {
    [ClarabridgeChat sendFile:fileLocation withMetadata:metadata withProgress:^(double progress) {
        CLBEnsureMainThread(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationFileUploadProgressDidChangeNotification
                                                                object:self
                                                              userInfo:@{
                                                                         CLBConversationFileKey: fileLocation,
                                                                         CLBConversationProgressKey : @(progress)
                                                                         }];
            
            if(progressBlock){
                progressBlock(progress);
            }
        });
    } completion:^(NSError *error, NSDictionary *responseObject) {
        CLBMessage *message;
        NSError *responseError;
        
        if(!error){
            NSString *messageId = responseObject[@"messageId"];
            
            message = [self pendingMessageWithId:messageId];
            
            if (!message) {
                @synchronized(self) {
                    NSMutableDictionary *failedPendingUpload = self.failedFileUploads[messageId];
                    
                    if (failedPendingUpload) {
                        // Faye already reported the file as invalid, notify with error
                        responseError = failedPendingUpload[CLBPendingUploadErrorKey];
                        [self.failedFileUploads removeObjectForKey:messageId];
                    } else {
                        // Wait for message to come through Faye
                        NSMutableDictionary *pendingUpload = [NSMutableDictionary new];
                        
                        pendingUpload[CLBPendingUploadFileKey] = fileLocation;
                        
                        if (completionBlock) {
                            pendingUpload[CLBPendingUploadCompletionBlockKey] = completionBlock;
                        }
                        
                        if (!self.pendingFileUploads) {
                            self.pendingFileUploads = [NSMutableDictionary new];
                        }
                        
                        [self.pendingFileUploads setObject:pendingUpload forKey:messageId];
                        return;
                    }
                }
            }
        } else {
            NSMutableDictionary *errorUserInfo = [(error.userInfo ?: @{}) mutableCopy];
            [errorUserInfo addEntriesFromDictionary:(responseObject ?: @{})];
            NSInteger errorCode = errorUserInfo[CLBErrorStatusCode] ? [errorUserInfo[CLBErrorStatusCode] integerValue]: 500;
            responseError = [NSError errorWithDomain:CLBErrorDomainIdentifier code:errorCode userInfo:errorUserInfo];
        }
        
        [self notifyFileUploadCompleteForFile:fileLocation message:message error:responseError completion:completionBlock];
    }];
}

- (void)handleSuccessfulUpload:(CLBMessage *)message {
    BOOL notified = [self checkAndNotifyPendingUpload:message.messageId message:message error:nil];
    
    if (!notified) {
        @synchronized(self) {
            if (!self.pendingFileUploads) {
                self.pendingFileUploads = [NSMutableDictionary new];
            }
            
            [self.pendingFileUploads setObject:@{CLBPendingUploadMessageKey: message} forKey:message.messageId];
        }
    }
}

- (void)handleFailedUpload:(CLBFailedUpload *)failedUpload {
    BOOL notified = [self checkAndNotifyPendingUpload:failedUpload.messageId message:nil error:failedUpload.error];
    
    if (!notified) {
        // File upload request hasn't finished
        @synchronized(self) {
            if (!self.failedFileUploads) {
                self.failedFileUploads = [NSMutableDictionary new];
            }
            
            [self.failedFileUploads setObject:@{CLBPendingUploadErrorKey: failedUpload.error} forKey:failedUpload.messageId];
        }
    }
}

- (void)notifyFileUploadCompleteForFile:(NSURL *)fileLocation
                                message:(CLBMessage *)message
                                  error:(NSError *)error
                             completion:(CLBFileUploadCompletionBlock)completionBlock {
    if (message && ![self messageWithIdExists:message.messageId]) {
        @synchronized(self) {
            [self insertObject:message inMessagesAtIndex:[self.internalMessages count]];
            [self saveToDisk];
        }
    }
    
    CLBEnsureMainThread(^{
        if(completionBlock){
            completionBlock(error, message);
        }
        
        NSMutableDictionary* userInfo = [NSMutableDictionary new];
        
        if (fileLocation) {
            [userInfo setObject:fileLocation forKey:CLBConversationFileKey];
        }
        
        if (error) {
            userInfo[CLBConversationErrorKey] = error;
        } else {
            userInfo[CLBConversationMessageKey] = message;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationFileUploadCompletedNotification object:self userInfo:userInfo];
    });
}

- (void)sendImage:(UIImage *)image
     withProgress:(CLBImageUploadProgressBlock)progressBlock
       completion:(CLBImageUploadCompletionBlock)completionBlock {
    if (!image) {
        NSLog(@"<CLARABRIDGECHAT::WARNING> Ignoring an image upload with nil image");
        return;
    }

    NSDictionary* metadata;
    if ([self.delegate respondsToSelector:@selector(conversation:willSendMessage:)]) {
        CLBMessage* fakeMessage = [[CLBMessage alloc] init];
        fakeMessage.type = CLBMessageTypeImage;

        CLBMessage* modifiedMessage = [self.delegate conversation:self willSendMessage:fakeMessage];
        if(modifiedMessage.metadata) {
            metadata = modifiedMessage.metadata;
        }
    }

    CLBEnsureMainThread(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationImageUploadDidStartNotification
                                                            object:self
                                                          userInfo:@{
                                                                     CLBConversationImageKey: image
                                                                     }];
    });
    
    [self cancelTyping];

    if (self.conversationId == nil) {
        [ClarabridgeChat startConversationWithIntent:@"message:appUser" completionHandler:^(NSError *error, NSDictionary *userInfo) {
            if (!error) {
                [self sendImage:image withMetadata:metadata withProgress:progressBlock completion:completionBlock];
            } else {
                [self notifyImageUploadCompleteForImage:image message:nil error:error completion:completionBlock];
            }
        }];

        return;
    }

    [self sendImage:image withMetadata:metadata withProgress:progressBlock completion:completionBlock];
}

- (void)sendImage:(UIImage *)image
     withMetadata:(NSDictionary*)metadata
     withProgress:(CLBImageUploadProgressBlock)progressBlock
       completion:(CLBImageUploadCompletionBlock)completionBlock {
    [ClarabridgeChat sendImage:image withMetadata:metadata withProgress:^(double progress) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationImageUploadProgressDidChangeNotification
                                                            object:self
                                                          userInfo:@{
                                                                     CLBConversationImageKey: image,
                                                                     CLBConversationProgressKey : @(progress)
                                                                     }];

        if(progressBlock){
            progressBlock(progress);
        }
    } completion:^(NSError* error, NSDictionary* responseObject) {
        CLBMessage *message;
        NSError *responseError;
        
        if(!error){
            NSString *messageId = responseObject[@"messageId"];
            
            message = [self pendingMessageWithId:messageId];
            
            if (!message) {
                @synchronized(self) {
                    NSMutableDictionary *failedPendingUpload = self.failedFileUploads[messageId];
                    
                    if (failedPendingUpload) {
                        // Faye already reported the file as invalid, notify with error
                        responseError = failedPendingUpload[CLBPendingUploadErrorKey];
                        [self.failedFileUploads removeObjectForKey:messageId];
                    } else {
                        // Wait for message to come through Faye
                        NSMutableDictionary *pendingUpload = [NSMutableDictionary new];
                        
                        pendingUpload[CLBPendingUploadImageKey] = image;
                        
                        if (completionBlock) {
                            pendingUpload[CLBPendingUploadCompletionBlockKey] = completionBlock;
                        }
                        
                        if (!self.pendingFileUploads) {
                            self.pendingFileUploads = [NSMutableDictionary new];
                        }
                        
                        [self.pendingFileUploads setObject:pendingUpload forKey:messageId];
                        return;
                    }
                }
            }
        } else {
            NSMutableDictionary *errorUserInfo = [(error.userInfo ?: @{}) mutableCopy];
            [errorUserInfo addEntriesFromDictionary:(responseObject ?: @{})];
            
            NSInteger errorCode = errorUserInfo[CLBErrorStatusCode] ? [errorUserInfo[CLBErrorStatusCode] integerValue]: 500;
            responseError = [NSError errorWithDomain:CLBErrorDomainIdentifier code:errorCode userInfo:errorUserInfo];
        }
        
        [self notifyImageUploadCompleteForImage:image message:message error:responseError completion:completionBlock];
    }];
}

- (void)notifyImageUploadCompleteForImage:(UIImage *)image
                                  message:(CLBMessage *)message
                                    error:(NSError *)error
                               completion:(CLBImageUploadCompletionBlock)completionBlock {
    if (message && ![self messageWithIdExists:message.messageId]) {
        @synchronized(self){
            [self insertObject:message inMessagesAtIndex:[self.internalMessages count]];
            [self saveToDisk];
        }
    }
    
    CLBEnsureMainThread(^{
        if(completionBlock){
            completionBlock(error, message);
        }

        NSMutableDictionary* userInfo = [@{ CLBConversationImageKey: image } mutableCopy];
        if(error){
            userInfo[CLBConversationErrorKey] = error;
        }else{
            userInfo[CLBConversationMessageKey] = message;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationImageUploadCompletedNotification object:self userInfo:userInfo];
    });
}

- (void)sendMessage:(CLBMessage *)message {
    if (self.conversationId != nil &&
        [ClarabridgeChat dependencyManager].conversation != nil &&
        ![[ClarabridgeChat dependencyManager].conversation.conversationId isEqualToString:self.conversationId]) {
        NSLog(@"<CLARABRIDGECHAT::WARNING> Unable to send messages to conversations if they are not the active conversation. Load conversation first.");
        return;
    }

    message.isFromCurrentUser = YES;
    if ([self.delegate respondsToSelector:@selector(conversation:willSendMessage:)]) {
        message = [self.delegate conversation:self willSendMessage:message];
    }

    if (message.uploadStatus != CLBMessageUploadStatusUnsent){
        NSLog(@"<CLARABRIDGECHAT::WARNING> Ignoring a message with upload status different from CLBMessageUploadStatusUnsent");
        return;
    }

    NSString* trimmedText = [message.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if ([CLBMessageTypeText isEqualToString:message.type] && trimmedText.length == 0){
        NSLog(@"<CLARABRIDGECHAT::WARNING> Ignoring a message of type text with no text");
        return;
    }

    if ([CLBMessageTypeLocation isEqualToString:message.type] && ![message hasCoordinates]){
        NSLog(@"<CLARABRIDGECHAT::WARNING> Ignoring a message of type location with no coordinates");
        return;
    }

    [self addMessage:message];
    [self cancelTyping];
}

- (void)addMessage:(CLBMessage *)message {
    @synchronized(self){
        if(message.uploadStatus == CLBMessageUploadStatusSent && message.isFromCurrentUser){
            BOOL isSendingMessage = NSNotFound != [self.internalMessages indexOfObjectWithOptions:NSEnumerationReverse
                                                                                      passingTest:^BOOL(CLBMessage* obj, NSUInteger idx, BOOL *stop) {
                                                                                          return [message isEqualWithoutDate:obj];
                                                                                      }];

            if(isSendingMessage){
                return;
            }
        }

        message.conversation = self;
        [self insertObject:message inMessagesAtIndex:[self.messages count]];
        
        [self saveToDisk];
    }
}

- (BOOL)checkAndNotifyPendingUpload:(NSString *)messageId message:(CLBMessage *)message error:(NSError *)error {
        NSMutableDictionary *pendingUpload = self.pendingFileUploads[messageId];
        
        if (pendingUpload) {
            BOOL isImageUpload = pendingUpload[CLBPendingUploadImageKey] != nil;
            
            if (isImageUpload) {
                [self notifyImageUploadCompleteForImage:pendingUpload[CLBPendingUploadImageKey]
                                                message:message
                                                  error:error completion:
                 pendingUpload[CLBPendingUploadCompletionBlockKey]];
            } else {
                [self notifyFileUploadCompleteForFile:pendingUpload[CLBPendingUploadFileKey]
                                              message:message
                                                error:error
                                           completion:pendingUpload[CLBPendingUploadCompletionBlockKey]];
            }
            
            [self.pendingFileUploads removeObjectForKey:messageId];
            
            return YES;
        }
        
        return NO;
}

- (void)postback:(CLBMessageAction *)action completion:(void (^)(NSError *))completionBlock {
    if (!action) {
        NSLog(@"<CLARABRIDGECHAT::WARNING> Ignoring a postback with nil action");
        return;
    }

    if ([action.uiState isEqualToString:CLBMessageActionUIStateProcessing]) {
        NSLog(@"<CLARABRIDGECHAT::WARNING> Ignoring a postback on action that is currently processing");
        return;
    }

    [ClarabridgeChat postback:action toConversation:self completion:completionBlock];
}

- (void)retryMessage:(CLBMessage *)failedMessage {
    if (failedMessage.uploadStatus != CLBMessageUploadStatusFailed) {
        NSLog(@"<CLARABRIDGECHAT::WARNING> Tried to retry a message that did not fail.");
        return;
    }
    CLBMessage *newMessage;

    if ([CLBMessageTypeLocation isEqualToString:failedMessage.type]) {
        newMessage = [[CLBMessage alloc] initWithCoordinates:failedMessage.coordinates payload:failedMessage.payload metadata:failedMessage.metadata];
    } else {
        newMessage = [[CLBMessage alloc] initWithText:failedMessage.text payload:failedMessage.payload metadata:failedMessage.metadata];
    }

    newMessage.isFromCurrentUser = failedMessage.isFromCurrentUser;

    @synchronized(self){
        [self.internalMessages removeObject:failedMessage];
        [self sendMessage:newMessage];
    }
}

- (CLBMessage *)pendingMessageWithId:(NSString *)messageId {
    @synchronized(self){
        NSDictionary *pendingMessage = self.pendingFileUploads[messageId];
        return pendingMessage[CLBPendingUploadMessageKey];
    }
}

- (BOOL)messageWithIdExists:(NSString *)messageId {
    for (CLBMessage *message in self.internalMessages) {
        if ([message.messageId isEqualToString:messageId]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)conversationStarted {
    return self.user.conversationStarted || [ClarabridgeChat dependencyManager].config.multiConvoEnabled;
}

- (void)markAllAsRead {
    for (CLBParticipant *participant in self.internalParticipants) {
        if ([participant.userId isEqualToString:self.user.userId]) {
            if ([participant.unreadCount intValue] > 0) {
                participant.unreadCount = [NSNumber numberWithInt:0];
                self.unreadCount = 0;
                [self saveToDisk];
                [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationDidMarkAllAsReadNotification object:self];
            }
        }
    }
}

- (void)loadPreviousMessages {
    [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationDidRequestPreviousMessagesNotification object:self];
}

- (void)notifyUnreadCountChanged {
    CLBEnsureMainThread(^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(conversation:unreadCountDidChange:)]) {
            [self.delegate conversation:self unreadCountDidChange:self.unreadCount];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationUnreadCountDidChangeNotification object:self];
    });
}

- (NSUInteger)unreadCount {
    return _unreadCount;
}

- (void)setUnreadCount:(NSUInteger)unreadCount {
    if (unreadCount != _unreadCount) {
        _unreadCount = unreadCount;
        [self notifyUnreadCountChanged];
    }
}

- (NSUInteger)messageCount {
    return [self.internalMessages count];
}

- (void)startTyping {
    NSDate* now = [NSDate date];
    self.lastTypingStartEvent = now;
    
    BOOL didUploadTypingStart = self.lastUploadedTypingStartEvent != nil;
    BOOL didUploadTypingStartRecently = ABS([self.lastUploadedTypingStartEvent timeIntervalSinceDate:now]) <= kTypingEventTimeoutSeconds;
    
    if (!didUploadTypingStart || !didUploadTypingStartRecently) {
        self.lastUploadedTypingStartEvent = now;
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationTypingDidStartNotification object:self];
    }
    
    [self.typingTimeoutTimer invalidate];
    self.typingTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:kTypingEventTimeoutSeconds
                                                               target:self
                                                             selector:@selector(stopTyping)
                                                             userInfo:nil
                                                              repeats:NO];
}

- (void)stopTyping {
    [self.typingTimeoutTimer invalidate];
    self.typingTimeoutTimer = nil;
    
    NSDate* lastTypingStart = self.lastTypingStartEvent;
    if (!lastTypingStart) {
        return;
    }
    
    // Wait a bit to see if the user starts typing again
    [self executeAfterStopTypingBuffer:^{
        @synchronized(self) {
            BOOL typingAlreadyStopped = self.lastTypingStartEvent == nil;
            BOOL userDidStartTyping = lastTypingStart != self.lastTypingStartEvent;
            
            if (!typingAlreadyStopped && !userDidStartTyping) {
                self.lastTypingStartEvent = nil;
                self.lastUploadedTypingStartEvent = nil;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationTypingDidStopNotification object:self];
            }
        }
    }];
}

- (void)executeAfterStopTypingBuffer:(void (^)(void))block {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTypingStopBufferSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        block();
    });
}

- (void)cancelTyping {
    [self.typingTimeoutTimer invalidate];
    self.typingTimeoutTimer = nil;
    self.lastTypingStartEvent = nil;
    self.lastUploadedTypingStartEvent = nil;
}

#pragma mark - KVO for Messages Array

- (NSUInteger)countOfMessages {
    return [self.internalMessages count];
}

- (id)objectInMessagesAtIndex:(NSUInteger)index {
    return (self.internalMessages)[index];
}

- (void)insertObject:(CLBMessage*)message inMessagesAtIndex:(NSUInteger)index {
    [self.internalMessages insertObject:message atIndex:index];
}

- (void)removeMessagesAtIndexes:(NSIndexSet *)indexes {
    [self.internalMessages removeObjectsAtIndexes:indexes];
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    @synchronized(self){
        [coder encodeObject:self.conversationId forKey:@"conversationId"];
        [coder encodeInteger:self.unreadCount forKey:@"unreadCount"];
        [coder encodeObject:self.metadata forKey:@"metadata"];
        
        NSMutableArray* sentMessages = [NSMutableArray arrayWithArray:[self.internalMessages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"uploadStatus != %ld", CLBMessageUploadStatusUnsent]]];
        [coder encodeObject:[NSMutableArray arrayWithArray:sentMessages] forKey:@"messages"];

        [coder encodeBool:self.hasPreviousMessages forKey:@"hasPreviousMessages"];
        [coder encodeObject:self.businessLastRead forKey:@"appMakerLastRead"];
        [coder encodeObject:self.internalParticipants forKey:@"participants"];
        [coder encodeObject:self.displayName forKey:@"displayName"];
        [coder encodeObject:self.conversationDescription forKey:@"description"];
        [coder encodeObject:self.iconUrl forKey:@"iconUrl"];
        [coder encodeObject:self.lastUpdatedAt forKey:@"lastUpdatedAt"];
    }
}

// MARK: NSCopying

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    CLBConversation *conversation = [[[self class] alloc] init];
    if (conversation) {
        conversation.conversationId = _conversationId.copy;
        conversation.unreadCount = _unreadCount;
        conversation.metadata = _metadata.copy;
        conversation.internalMessages = _internalMessages.copy;
        conversation.hasPreviousMessages = _hasPreviousMessages;
        conversation.businessLastRead = _businessLastRead.copy;
        conversation.internalParticipants = _internalParticipants.copy;
        conversation.displayName = _displayName.copy;
        conversation.conversationDescription = _conversationDescription.copy;
        conversation.iconUrl = _iconUrl.copy;
        conversation.lastUpdatedAt = _lastUpdatedAt.copy;
    }
    return conversation;
}

@end
