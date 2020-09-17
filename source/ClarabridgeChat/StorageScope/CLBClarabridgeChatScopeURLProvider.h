//
//  CLBClarabridgeChatScopeURLProvider.h
//  ClarabridgeChat
//
//  Created by Alan Egan on 22/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBScopeURLProvider.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CLBSunshineConversationsDomain;

CLB_FINAL_CLASS
@interface CLBClarabridgeChatScopeURLProvider : NSObject <CLBScopeURLProvider>

- (instancetype)initWithScopePath:(NSString *)baseScopePath;

@end

NS_ASSUME_NONNULL_END
