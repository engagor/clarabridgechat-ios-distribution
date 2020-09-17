//
//  CLBConversationStorage.h
//  ClarabridgeChat
//
//  Created by Alan Egan on 22/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBStorage.h"

@class CLBConversation;

NS_ASSUME_NONNULL_BEGIN

CLB_FINAL_CLASS
@interface CLBConversationStorage : NSObject

- (instancetype)initWithStorage:(id<CLBStorage>)storage;
- (void)storeConversation:(CLBConversation *)conversation;
- (CLBConversation * _Nullable)findConversationById:(NSString *)conversationId;
- (void)removeConversationById:(NSString *)conversationId;
- (void)clear;

@end

NS_ASSUME_NONNULL_END


