//
//  CLBCreateConversationButton.m
//  ClarabridgeChat
//
//  Created by Pete Smith on 30/07/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBCreateConversationButton.h"
#import "CLBLocalization.h"

CGFloat const kConversationButtonHeight = 48.0;

@implementation CLBCreateConversationButton

+ (CLBCreateConversationButton *)createConversationButtonWithColor:(UIColor *)color; {

    CLBCreateConversationButton *button = [super buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = color;

    button.translatesAutoresizingMaskIntoConstraints = NO;

    [button.heightAnchor constraintEqualToConstant:kConversationButtonHeight].active = YES;
    button.layer.cornerRadius = 24;

    [button setTitle:[CLBLocalization localizedStringForKey:@"Create conversation"] forState:UIControlStateNormal];

    return button;
}

@end
