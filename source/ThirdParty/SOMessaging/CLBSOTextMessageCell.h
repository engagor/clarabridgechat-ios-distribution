//
//  SOTextMessageCell.h
//  ClarabridgeChat
//
//  Created by Mike on 2014-06-17.
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBSOMessageCell.h"
@class CLBTextViewVendingMachine;

static const UIEdgeInsets CLBSOMessageCellTextViewPadding = { 9, 12, 9, 12 };

@interface CLBSOTextMessageCell : CLBSOMessageCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier vendingMachine:(CLBTextViewVendingMachine*)vendingMachine;

@property CLBTextViewVendingMachine* vendingMachine;

-(void)layoutContentWithFixedWidth:(CGFloat)fixedWidth;
-(void)adjustContentBelowFrame:(CGRect)frame;

-(BOOL)hasReplyActions;

+(CGFloat)extraHeightForMessage:(id<CLBSOMessage>)message withWidth:(CGFloat)maxWidth;

@property NSMutableArray* actionButtons;

@end
