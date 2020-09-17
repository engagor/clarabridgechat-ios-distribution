//
//  CLBConversationListStorage.h
//  ClarabridgeChat
//
//  Created by Alan O'Connor on 15/01/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBStorage.h"

@class CLBConversationList;

NS_ASSUME_NONNULL_BEGIN

CLB_FINAL_CLASS
@interface CLBConversationListStorage : NSObject

- (instancetype)initWithStorage:(id<CLBStorage>)storage;
- (void)storeConversationList:(CLBConversationList *)conversationList;
- (CLBConversationList * _Nullable)getConversationList;
- (void)clear;

@end

NS_ASSUME_NONNULL_END
