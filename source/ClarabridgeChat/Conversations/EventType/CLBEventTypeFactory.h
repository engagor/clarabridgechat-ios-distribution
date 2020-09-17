//
//  CLBEventTypeFactory.h
//  ClarabridgeChat
//
//  Created by Shona Nunez on 14/01/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLBConversation, CLBConversationStorageManager, CLBConversationFetchScheduler;
@protocol CLBConversationFetchSchedulerProtocol, CLBUtilitySettings, CLBEventTypeFactoryDelegate;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CLBEventType) {
    CLBEventTypeUnknown,
    CLBEventTypeMessage,
    CLBEventTypeUploadFailed,
    CLBEventTypeActivity,
    CLBEventTypeConversationAdded,
    CLBEventTypeConversationRemoved,
    CLBEventTypeParticipantAdded,
    CLBEventTypeParticipantRemoved
};

CLB_FINAL_CLASS
@interface CLBEventTypeFactory : NSObject

- (instancetype)initWithConversation:(CLBConversation *)conversation
                     utilitySettings:(id<CLBUtilitySettings>)utilitySettings;

- (CLBEventType)eventTypeFromString:(NSString *)type;
- (void)handleEventType:(CLBEventType)type withEvent:(NSDictionary *)event;

@property (weak) id<CLBEventTypeFactoryDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
