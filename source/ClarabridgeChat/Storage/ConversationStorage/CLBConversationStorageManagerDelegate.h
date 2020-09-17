//
//  CLBConversationStorageManagerDelegate.h
//  ClarabridgeChat
//
//  Created by Shona Nunez on 28/01/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CLBConversation;

NS_ASSUME_NONNULL_BEGIN

@protocol CLBConversationStorageManagerDelegate <NSObject>

- (void)conversationHasChanged:(CLBConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
