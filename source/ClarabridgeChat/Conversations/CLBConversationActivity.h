//
//  CLBConversationActivity.h
//  ClarabridgeChat
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  @abstract An activity type indicating that a participant of the converation started typing a response
 */
extern NSString *const CLBConversationActivityTypeTypingStart;

/**
 *  @abstract An activity type indicating that a participant of the converation stopped typing a response
 */
extern NSString *const CLBConversationActivityTypeTypingStop;

/**
 *  @abstract An activity type indicating that a participant of the converation recently read the user message
 *
 *  This event type is triggered for the current user when the conversation is read on a different device. 
 */
extern NSString *const CLBConversationActivityTypeConversationRead;

/**
 *  @abstract An activity type indicating that the current user was added to a conversation
 */
extern NSString *const CLBConversationActivityTypeConversationAdded;

/**
 *  @abstract An activity type indicating that the current user was removed from a conversation
 */
extern NSString *const CLBConversationActivityTypeConversationRemoved;

/**
 *  @abstract An activity type indicating that another user was added to a conversation that the current user is part of
 */
extern NSString *const CLBConversationActivityTypeParticipantAdded;

/**
 *  @abstract An activity type indicating that another user was removed from a conversation that the current user is part of
 */
extern NSString *const CLBConversationActivityTypeParticipantRemoved;

/**
 *  @abstract A key whose value is an NSString representing the business name.
 *
 *  @discussion This key is used in the CLBConversationActivity data object.
 */
extern NSString *const CLBConversationActivityDataNameKey;

/**
 *  @abstract A key whose value is an NSString representing the URL of the business avatar.
 *
 *  @discussion This key is used in the CLBConversationActivity data object.
 */
extern NSString *const CLBConversationActivityDataAvatarUrlKey;

@interface CLBConversationActivity : NSObject

/**
 *  @abstract the role of who is performing the typing activity
 */
@property(readonly, nullable) NSString *role;

/**
 *  @abstract the type of activity that is being triggered. Could be either
 *   - CLBConversationActivityTypeTypingStart
 *   - CLBConversationActivityTypeTypingStop
 *   - CLBConversationActivityTypeConversationRead
 *   - CLBConversationActivityTypeConversationAdded
 *   - CLBConversationActivityTypeConversationRemoved
 *   - CLBConversationActivityTypeParticipantAdded
 *   - CLBConversationActivityTypeParticipantRemoved
 */
@property(readonly) NSString *type;

/**
 *  @abstract additional data for this activity. Posible values are the business's 'name' and/or 'avatarUrl'
 */
@property(readonly, nullable) NSDictionary *data;

/**
 *  @abstract conversationId for activity. Can be nil
 */
@property(readonly, nullable) NSString *conversationId;

/**
 *  @abstract date when the business last read user messages for activities of type CLBConversationActivityTypeConversationRead
 */
@property(readonly, nullable) NSDate *businessLastRead;

/**
 * @abstract The userId if available, null otherwise
 *
 * available for CLBConversationActivityTypeParticipantAdded, CLBConversationActivityTypeParticipantRemoved
 */
@property(readonly, nullable) NSString *userId;

@end
NS_ASSUME_NONNULL_END
