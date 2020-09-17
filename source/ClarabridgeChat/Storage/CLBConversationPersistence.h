//
//  CLBConversationPersistence.h
//  ClarabridgeChat
//
//  Created by Alan O'Connor on 21/01/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CLBConversation;

NS_ASSUME_NONNULL_BEGIN

@protocol CLBConversationPersistence <NSObject>

- (void)storeConversation:(CLBConversation *)conversation;
- (CLBConversation * _Nullable)readConversation:(NSString *)conversationId;
- (void)removeConversation:(NSString *)conversationId;
- (void)conversationHasChanged:(CLBConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
