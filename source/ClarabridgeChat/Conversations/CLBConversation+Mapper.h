//
//  CLBConversation+Mapper.h
//  ClarabridgeChat
//
//  Created by Thaciana Lima on 04/06/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBConversation.h"
@class CLBConversationViewModel;
@class CLBUser;

NS_ASSUME_NONNULL_BEGIN

@interface CLBConversation (Mapper)

- (CLBConversationViewModel *)conversationViewModelWithAppAvatarURLString:(NSString *)appAvatarUrlString appName:(nullable NSString *)appName users:(NSArray<CLBUser *> *)users;
- (NSString *)buildLastMessageWithMessage:(CLBMessage *)message andDefaultName:(nullable NSString *)defaultName andUsers:(NSArray<CLBUser *> *)users;

@end

NS_ASSUME_NONNULL_END
