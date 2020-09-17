//
//  CLBClarabridgeChatApiClient.h
//  ClarabridgeChat
//
//  Copyright © 2019 Smooch Technologies. All rights reserved.
//

#import "CLBApiClient.h"
#import "CLBAuthenticationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface CLBClarabridgeChatApiClient : CLBApiClient

-(instancetype)initWithBaseURL:(NSString *)url authenticationDelegate:(_Nullable id<CLBAuthenticationDelegate>)authenticationDelegate completion:(_Nullable CLBAuthenticationCompletionBlock)callback;

@end

NS_ASSUME_NONNULL_END
