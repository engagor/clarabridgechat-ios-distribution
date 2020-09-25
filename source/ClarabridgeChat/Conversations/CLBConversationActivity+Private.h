//
//  CLBConversationActivity.h
//  ClarabridgeChat
//
//  Copyright © 2016 Smooch Technologies. All rights reserved.

#import <Foundation/Foundation.h>
#import <ClarabridgeChat/CLBConversationActivity.h>
#import "CLBSOMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface CLBConversationActivity (Private) <CLBSOMessage>

@property(readwrite, nullable) NSDate *businessLastRead;
@property(readwrite, nullable) NSString *conversationId;
@property(readwrite, nullable) NSString *userId;
@property(readwrite) NSString *type;

-(instancetype)initWithRole:(NSString *)role
                       type:(NSString *)type
                       data:(nullable NSDictionary *)data
               conversation:(nullable NSDictionary *)conversation;

-(instancetype)initWithDictionary:(NSDictionary *) dictionary;

@end
NS_ASSUME_NONNULL_END
