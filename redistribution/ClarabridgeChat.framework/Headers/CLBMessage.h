//
//  CLBMessage.h
//  ClarabridgeChat
//

#import <UIKit/UIKit.h>
#import "CLBCoordinates.h"
#import "CLBDisplaySettings.h"

/**
 *  @abstract Notification that is fired when a message fails to upload.
 */
extern NSString* _Nonnull const CLBMessageUploadFailedNotification;

/**
 *  @abstract Notification that is fired when a message uploads successfully.
 */
extern NSString* _Nonnull const CLBMessageUploadCompletedNotification;

/**
 *  @abstract A type of message that contains an image, text, and/or action buttons
 */
extern NSString* _Nonnull const CLBMessageTypeImage;

/**
 *  @abstract A type of message that contains text and/or action buttons
 */
extern NSString* _Nonnull const CLBMessageTypeText;

/**
 *  @abstract A type of message that contains a location
 */
extern NSString* _Nonnull const CLBMessageTypeLocation;

/**
 *  @abstract A type of message that contains a file and/or text
 */
extern NSString* _Nonnull const CLBMessageTypeFile;

/**
 *  @abstract A type of message that contains a horizontally scrollable set of items
 */
extern NSString* _Nonnull const CLBMessageTypeCarousel;

/**
 *  @abstract A type of message that contains a vertically scrollable set of items
 */
extern NSString* _Nonnull const CLBMessageTypeList;

/**
 *  @discussion Upload status of an CLBMessage.
 *
 *  @see CLBMessage
 */
typedef NS_ENUM(NSInteger, CLBMessageUploadStatus) {
    /**
     *  A user message that has not yet finished uploading.
     */
    CLBMessageUploadStatusUnsent,
    /**
     *  A user message that failed to upload.
     */
    CLBMessageUploadStatusFailed,
    /**
     *  A user message that was successfully uploaded.
     */
    CLBMessageUploadStatusSent,
    /**
     *  A message that did not originate from the current user.
     */
    CLBMessageUploadStatusNotUserMessage
};

@interface CLBMessage : NSObject <NSSecureCoding>

/**
 *  @abstract Create a message with the given text. The message will be owned by the current user.
 */
-(nonnull instancetype)initWithText:(nonnull NSString*)text;

/**
 *  @abstract Create a message with the given text, payload, and metadata. The message will be owned by the current user
 */
-(nonnull instancetype)initWithText:(nonnull NSString *)text payload:(nullable NSString *)payload metadata:(nullable NSDictionary *)metadata;

/**
 *  @abstract Create a message with the given coordinates, payload, and metadata. The message will be owned by the current user
 */
-(nonnull instancetype)initWithCoordinates:(nonnull CLBCoordinates *)coordinates payload:(nullable NSString *)payload metadata:(nullable NSDictionary *)metadata;

/**
 *  @abstract The unique identifier of the message. May be nil if a unique identifier has not been generated for this message
 */
@property(readonly, nullable) NSString* messageId;

/**
 *  @abstract The text content of the message. May be nil if mediaUrl or actions are provided
 */
@property(nullable) NSString* text;

/**
 *  @abstract The text fallback to display for message types not supported by the SDK. May be nil
 */
@property(nullable) NSString* textFallback;

/**
 *  @abstract The displayName of the author. This property may be nil if no displayName could be determined.
 */
@property(nullable) NSString* displayName;

/**
 *  @abstract The url for the author's avatar image. May be nil
 */
@property(nullable) NSString* avatarUrl;

/**
 *  @abstract The date and time the message was sent
 */
@property(nullable) NSDate *date;

/**
 *  @abstract Returns YES if the message originated from the user, or NO if the message comes from the app team.
 */
@property (nonatomic) BOOL isFromCurrentUser;

/**
 *  @abstract The upload status of the message.
 *
 *  @see CLBMessageStatus
 */
@property(readonly) CLBMessageUploadStatus uploadStatus;

/**
 *  @abstract An array of CLBMessageAction objects representing the actions associated with this message (if any)
 *
 *  @discussion This array may be nil or empty, so check the length of the array to know if a message has actions or not.
 *
 *  @see CLBMessageAction
 */
@property(readonly, nullable) NSArray* actions;

/**
 *  @abstract An array of CLBMessageItem objects representing the items associated with this message
 *
 *  @discussion Only messages of type `CLBMessageTypeCarousel` and `CLBMessageTypeList` contain items.
 *
 *  @see CLBMessageItem
 */
@property(readonly, nullable) NSArray* items;

/**
 *  @abstract The url to the media asset, if applicable. Returns nil if the message is not an image or file message.
 */
@property(nullable) NSString* mediaUrl;

/**
 *  @abstract The size of the media asset in bytes. May be nil.
 */
@property(nullable) NSNumber* mediaSize;

/**
 *  @abstract The type the message.
 *
 *  @discussion Valid types include CLBMessageTypeText, CLBMessageTypeImage, and CLBMessageTypeLocation
 */
@property(nullable) NSString* type;

/**
 *  @abstract Coordinates for a location for a message of type CLBMessageTypeLocation
 */
@property(readonly, nullable) CLBCoordinates *coordinates;

/**
 *  @abstract Settings to adjust the layout of a message of type CLBMessageTypeCarousel
 *
 *  @see CLBDisplaySettings
 */
@property(readonly, nullable) CLBDisplaySettings *displaySettings;

/**
 *  @abstract The role of the message.
 *
 *  @discussion Valid roles include `appUser`, `business`, and `whisper`. Messages created with -initWithText: have role of `appUser`.
 */
@property(readonly, nullable) NSString* role;

/**
 *  @abstract Metadata associated with the message.
 *
 *  @discussion A flat dictionary of metadata set through the REST API. May be nil.
 */
@property(nullable) NSDictionary* metadata;

/**
 *  @abstract The payload of an action with type CLBMessageActionTypeReply
 *
 *  @discussion The payload of a CLBMessageActionTypeReply, if applicable. May be nil
 */
@property(nullable) NSString* payload;

@end
