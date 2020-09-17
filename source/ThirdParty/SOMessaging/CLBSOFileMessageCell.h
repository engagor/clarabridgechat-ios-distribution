//
//  CLBSOFileMessageCell.h
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBSOMessageCell.h"
#import "CLBSOMessage.h"
#import "CLBTextViewVendingMachine.h"

@interface CLBSOFileMessageCell : CLBSOMessageCell

+(CGFloat)heightForMessage:(id<CLBSOMessage>) message withVendingMachine:(CLBTextViewVendingMachine *)vendingMachine maxWidth:(CGFloat)maxWidth;

@end
