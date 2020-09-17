//
//  SOTextMessageCell.m
//  ClarabridgeChat
//
//  Created by Mike on 2014-06-17.
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBSOTextMessageCell.h"
#import "CLBUtility.h"
#import "CLBTextViewVendingMachine.h"
#import "CLBRoundedRectView.h"
#import "CLBMessageAction+Private.h"
#import "CLBProgressButton.h"
#import "CLBLocalization.h"
#import "CLBCheckmarkView.h"
#import "CLBActionButton.h"

static const CGFloat kHorizontalPadding = 10;

static const CGFloat kButtonMinimumHeight = 40;
static const CGFloat kSmallFontSize = 14;

static const CGFloat kButtonTitleVerticalInset = 8;
static const CGFloat kButtonTitleHorizontalInset = 28;
static const CGFloat kButtonTopMargin = 13;
static const CGFloat kBetweenButtonMargin = 7;

@interface CLBSOTextMessageCell() < UITextViewDelegate >

@property (strong, nonatomic) UITextView *textView;

@end

@implementation CLBSOTextMessageCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier vendingMachine:(CLBTextViewVendingMachine*)vendingMachine {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _vendingMachine = vendingMachine;
        
        _textView = [vendingMachine newTextView];
        _textView.delegate = self;
        _textView.opaque = YES;
        
        [self.containerView addSubview:_textView];
        
        _actionButtons = [NSMutableArray array];
    }
    
    return self;
}

-(void)layoutContent {
    [self layoutContentWithFixedWidth:NO value:-1];
}

-(void)layoutContentWithFixedWidth:(CGFloat)fixedWidth {
    // Image messages use a fixed bubble width. We need to calculate text size based on that fixed value
    [self layoutContentWithFixedWidth:YES value:fixedWidth];
}

-(void)layoutContentWithFixedWidth:(BOOL)fixedWidth value:(CGFloat)widthValue {
    [self.vendingMachine setTextForMessage:self.message onTextView:self.textView withAccentColor:self.accentColor userMessageTextColor:self.userMessageTextColor];
    
    CGSize textSize;
    
    if (fixedWidth) {
        textSize = [self.vendingMachine sizeForMessage:self.message constrainedToWidth:widthValue usingTextView:self.textView];
    } else {
        textSize = [self.vendingMachine sizeForMessage:self.message constrainedToWidth:self.messageMaxWidth usingTextView:self.textView];
    }
    
    CGRect frame = self.textView.frame;
    frame.size = textSize;
    frame.origin.y = CLBSOMessageCellTextViewPadding.top;
    frame.origin.x = kHorizontalPadding;
    
    if (fixedWidth) {
        frame.size.width = widthValue;
    }
    
    if (!self.message.isFromCurrentUser && self.userImage) {
        frame.origin.x += kUserImageViewRightMargin + self.userImageViewSize.width;
    }
    
    frame.origin.x += self.contentInsets.left - self.contentInsets.right;
    
    NSString *displayString = [self.vendingMachine textForMessage:self.message];
    NSString *trimmed = [displayString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if([trimmed length] == 0) {
        frame.size.height = 0;
    }
    
    [self layoutBubbleWithFixedWidth:fixedWidth withFrame:frame];
    
    self.textView.frame = frame;
}

-(void)layoutBubbleWithFixedWidth:(BOOL)fixedWidth withFrame:(CGRect)contentFrame {
    [self.actionButtons setValue:@YES forKey:@"hidden"];
    
    // Message with no text, only a button
    if(contentFrame.size.height == 0) {
        contentFrame.origin.y -= CLBSOMessageCellTextViewPadding.top;
    }
    
    BOOL shouldShowActions = self.message.actions.count > 0 && ![self hasReplyActions] && ![self hasLocationRequestAction];
    
    __block CGFloat bottomLayoutGuide = CGRectGetMaxY(contentFrame);
    
    __block CGFloat messageWidth = fixedWidth ? contentFrame.size.width : MAX(contentFrame.size.width, kMinimumMessageWidth);
    __block CGFloat buttonWidth = fixedWidth ? messageWidth : 0;
    
    UILabel* measurementLabel = [[self class] measurementLabelView];
    
    NSMutableArray<NSNumber*>* buttonHeights = [NSMutableArray array];
    
    // compute message & button width first to get the widest of the array
    [self.message.actions enumerateObjectsUsingBlock:^(CLBMessageAction* action, NSUInteger idx, BOOL *stop) {
        if(!shouldShowActions) {
            *stop = YES;
            return;
        }

        measurementLabel.text = [[self class] textForAction:action];
        measurementLabel.font = [[self class] fontForAction:action];
        
        CGSize buttonTitleSize;
        if (fixedWidth) {
            CGSize max = CGSizeMake(messageWidth - (kButtonTitleHorizontalInset * 2), CGFLOAT_MAX);
            buttonTitleSize = [measurementLabel sizeThatFits:max];
        } else {
            CGSize max = CGSizeMake(self.messageMaxWidth - (kButtonTitleHorizontalInset * 2), CGFLOAT_MAX);
            buttonTitleSize = [measurementLabel sizeThatFits:max];
            
            buttonWidth = MIN(buttonTitleSize.width + (2 * kButtonTitleHorizontalInset), self.messageMaxWidth);
            buttonWidth = MAX(buttonWidth, messageWidth);
            messageWidth = MAX(buttonWidth, messageWidth);
        }
        
        [buttonHeights addObject:@(MAX(buttonTitleSize.height + (2 * kButtonTitleVerticalInset), kButtonMinimumHeight))];
    }];
    
    [self.message.actions enumerateObjectsUsingBlock:^(CLBMessageAction* action, NSUInteger idx, BOOL *stop) {
        if(!shouldShowActions) {
            *stop = YES;
            return;
        }
        CLBActionButton* button;
        if(idx >= self.actionButtons.count){
            button = [self newButton];
        }else{
            button = self.actionButtons[idx];
        }
        
        [button setTitle:[[self class] textForAction:action] forState:UIControlStateNormal];
        button.hidden = NO;
        button.action = action;
        
        if([[self class] isPurchasedAction:action]){
            button.backgroundColor = [UIColor clearColor];
            button.layer.borderColor = CLBLightGrayColor().CGColor;
            button.layer.borderWidth = 1;
            [button setTitleColor:CLBMediumGrayColor() forState:UIControlStateNormal];
            button.enabled = NO;
        }else{
            button.backgroundColor = self.accentColor;
            button.layer.borderColor = nil;
            button.layer.borderWidth = 0;
            [button setTitleColor:self.userMessageTextColor forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.6] forState:UIControlStateHighlighted];
            button.enabled = YES;
        }
        button.titleLabel.font = [[self class] fontForAction:action];
        
        CGFloat topMargin = idx == 0 ? kButtonTopMargin : kBetweenButtonMargin;
        button.frame = CGRectMake(contentFrame.origin.x,
                                  bottomLayoutGuide + topMargin,
                                  buttonWidth,
                                  [buttonHeights[idx] doubleValue]);
        
        bottomLayoutGuide = CGRectGetMaxY(button.frame);
        
        if ([action.uiState isEqualToString:CLBMessageActionUIStateProcessing]) {
            [button setProcessing:YES];
        } else {
            [button setProcessing:NO];
        }
    }];
    
    contentFrame = CGRectMake(contentFrame.origin.x,
                              contentFrame.origin.y,
                              shouldShowActions ? messageWidth : contentFrame.size.width,
                              bottomLayoutGuide - contentFrame.origin.y);

    CGRect balloonFrame = CGRectZero;
    balloonFrame.size.width = contentFrame.size.width + 2* kHorizontalPadding;
    balloonFrame.size.height = CGRectGetMaxY(contentFrame) + CLBSOMessageCellTextViewPadding.bottom;
    balloonFrame.origin.y = 0;
    
    if (!self.message.isFromCurrentUser && self.userImage) {
        balloonFrame.origin.x = kUserImageViewRightMargin + self.userImageViewSize.width;
    }
    
    if (!CGSizeEqualToSize(self.userImageViewSize, CGSizeZero) && self.userImage) {
        if (balloonFrame.size.height < self.userImageViewSize.height) {
            balloonFrame.size.height = self.userImageViewSize.height;
        }
    }
    
    self.bubbleView.hidden = NO;
    self.bubbleView.frame = balloonFrame;
}

-(BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if([self.delegate respondsToSelector:@selector(messageCell:didSelectLink:)]){
        [self.delegate messageCell:self didSelectLink:URL];
        return NO;
    }
    
    return YES;
}

+(CGFloat)extraHeightForMessage:(id<CLBSOMessage>)message withWidth:(CGFloat)maxWidth {
    NSUInteger numActions = message.actions.count;
    
    if(numActions == 0){
        return 0;
    }
    
    BOOL hasRepliesOrLocationRequest = NO;
    
    for (CLBMessageAction *action in message.actions) {
        if ([CLBMessageActionTypeReply isEqualToString:action.type] || [CLBMessageActionTypeLocationRequest isEqualToString:action.type]) {
            hasRepliesOrLocationRequest = YES;
            break;
        }
    }
    
    if (hasRepliesOrLocationRequest) {
        return 0;
    }
    
    CGFloat actionHeight = 0;
    
    UILabel* measurementLabel = [self measurementLabelView];
    
    for (CLBMessageAction* action in message.actions) {
        if (actionHeight > 0) {
            actionHeight += kBetweenButtonMargin;
        }
        
        measurementLabel.text = [self textForAction:action];
        measurementLabel.font = [self fontForAction:action];

        CGSize textSize = [measurementLabel sizeThatFits:CGSizeMake(maxWidth - (kButtonTitleHorizontalInset * 2), CGFLOAT_MAX)];
        
        actionHeight += MAX(textSize.height + (2 * kButtonTitleVerticalInset), kButtonMinimumHeight);
    }
    
    actionHeight += kButtonTopMargin;
    
    NSString *trimmed = [message.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (numActions > 0 && [trimmed length] == 0) {
        actionHeight += CLBSOMessageCellTextViewPadding.bottom;
    }
    
    return actionHeight;
}


static UILabel* measurementLabel;
+(UILabel*)measurementLabelView {
    if(!measurementLabel){
        measurementLabel = [UILabel new];
        measurementLabel.numberOfLines = 0;
    }
    return measurementLabel;
}

-(CLBActionButton*)newButton {
    CLBActionButton* button = [[CLBActionButton alloc] init];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(kButtonTitleVerticalInset, kButtonTitleHorizontalInset, kButtonTitleVerticalInset, kButtonTitleHorizontalInset)];
    [button.titleLabel setTextAlignment:NSTextAlignmentCenter];
    button.titleLabel.numberOfLines = 0;
    
    [button addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.containerView addSubview:button];
    [self.actionButtons addObject:button];
    
    return button;
}

+(NSString*)textForAction:(CLBMessageAction*)action {
    BOOL isPurchased = [[self class] isPurchasedAction:action];
    
    if(isPurchased){
        return [CLBLocalization localizedStringForKey:@"Payment Completed"];
    }else{
        return action.text;
    }
}

-(void)actionButtonTapped:(CLBActionButton*)button {
    if([self.delegate respondsToSelector:@selector(messageCell:didSelectAction:)]){
        [self.delegate messageCell:self didSelectAction:button.action];
    }
}

+(BOOL)isPurchasedAction:(CLBMessageAction*)action {
    return [action.type isEqualToString:CLBMessageActionTypeBuy] && ![action.state isEqualToString:CLBMessageActionStateOffered];
}

-(BOOL)isReplyAction:(CLBMessageAction*)action {
    return [action.type isEqualToString:CLBMessageActionTypeReply];
}

-(BOOL)isLocationRequestAction:(CLBMessageAction*)action {
    return [action.type isEqualToString:CLBMessageActionTypeLocationRequest];
}

-(BOOL)hasReplyActions {
    for (CLBMessageAction *action in self.message.actions) {
        if ([self isReplyAction:action]) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)hasLocationRequestAction {
    for (CLBMessageAction *action in self.message.actions) {
        if ([self isLocationRequestAction:action]) {
            return YES;
        }
    }
    return NO;
}

+(UIFont*)fontForAction:(CLBMessageAction*)action {
    BOOL isPurchased = [self isPurchasedAction:action];
    
    if(isPurchased){
        if(CLBIsWideScreenDevice()){
            return [UIFont systemFontOfSize:kFontSize];
        }else{
            return [UIFont systemFontOfSize:kSmallFontSize];
        }
    }else{
        return [UIFont systemFontOfSize:kFontSize weight:UIFontWeightMedium];
    }
}

-(void)adjustContentBelowFrame:(CGRect) frame {
    for (UIView *button in self.actionButtons) {
        CGRect buttonFrame = button.frame;
        buttonFrame.origin.y += frame.size.height;
        button.frame = buttonFrame;
    }
    
    CGRect textFrame = self.textView.frame;
    textFrame.origin.y += frame.size.height;
    self.textView.frame = textFrame;
}

@end
