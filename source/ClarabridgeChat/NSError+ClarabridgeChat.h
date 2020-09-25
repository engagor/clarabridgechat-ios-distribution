//
//  NSError+ClarabridgeChat.h
//  ClarabridgeChat
//
//  Created by Pete Smith on 26/08/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const CLBClarabridgeChatErrorDomain;
extern NSString *const CLBClarabridgeChatErrorCreateConversationMultipartDescription;

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ClarabridgeChat)

+(instancetype)createConversationMultipartMessageError;

@end

NS_ASSUME_NONNULL_END
