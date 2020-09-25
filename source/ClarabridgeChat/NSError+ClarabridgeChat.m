//
//  NSError+ClarabridgeChat.m
//  ClarabridgeChat
//
//  Created by Pete Smith on 26/08/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "NSError+ClarabridgeChat.h"

NSString *const CLBClarabridgeChatErrorDomain = @"com.clarabridge";
NSString *const CLBClarabridgeChatErrorCreateConversationMultipartDescription = @"Invalid CLBMessage type. Only messages of type text are supported.";

@implementation NSError (ClarabridgeChat)

+(instancetype)createConversationMultipartMessageError {

    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:CLBClarabridgeChatErrorCreateConversationMultipartDescription forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:CLBClarabridgeChatErrorDomain code:999 userInfo:details];

    return error;
}

@end
