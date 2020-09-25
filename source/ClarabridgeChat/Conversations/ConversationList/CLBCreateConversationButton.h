//
//  CLBCreateConversationButton.h
//  ClarabridgeChat
//
//  Created by Pete Smith on 30/07/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern CGFloat const kConversationButtonHeight;

@interface CLBCreateConversationButton : UIButton

+ (CLBCreateConversationButton *)createConversationButtonWithColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
