//
//  CLBConversationList.h
//  ClarabridgeChat
//
//  Created by Alan O'Connor on 15/01/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLBUser;
@class CLBConversation;

NS_ASSUME_NONNULL_BEGIN
@interface CLBConversationList : NSObject <NSSecureCoding>

- (instancetype)initWithAppId:(NSString *)appId user:(CLBUser *)user;
- (void)deserialize:(NSDictionary *)object;
- (CLBConversation * _Nullable)getConversationById:(NSString *)conversationId;
- (void)appendConversationMessageToList:(CLBConversation *)conversation;

@property NSArray<CLBConversation *> *conversations;

@end

NS_ASSUME_NONNULL_END
