//
//  CLBConversationNavigationItemTitleView.h
//  ClarabridgeChat
//
//  Created by Thaciana Lima on 03/07/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLBConversationNavigationItemTitleView : UIView

- (instancetype)initWithTitleTextAttributes:(NSDictionary<NSAttributedStringKey, id> *)titleTextAttributes;
- (void)configWithTitle:(nullable NSString *)title subtitle:(nullable NSString *)subtitle avatar:(nullable UIImage *)avatar;
- (void)updateAvatar:(UIImage *)avatar;
- (void)adjustAvatarSizeToSize:(NSUInteger)size;

@end

NS_ASSUME_NONNULL_END
