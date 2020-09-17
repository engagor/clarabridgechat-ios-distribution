//
//  CLBRepliesView.m
//  ClarabridgeChat
//
//  Copyright © 2016 Smooch Technologies. All rights reserved.
//

#import "CLBRepliesView.h"
#import "CLBMessageAction.h"
#import "CLBImageLoader.h"
#import "ClarabridgeChat+Private.h"
#import "CLBReplyButton.h"

static const CGFloat kButtonHeight = 40;
static const CGFloat kButtonVerticalMargin = 7;
static const CGFloat kButtonHorizontalMargin = 7;

@interface CLBRepliesView()

@property NSMutableArray<CLBReplyButton *> *replyButtons;
@property NSInteger rows;
@property UIColor *color;

@end

@implementation CLBRepliesView

-(instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame color:nil];
}

-(instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color {
    self = [super initWithFrame:frame];
    if (self) {
        _replyButtons = [[NSMutableArray alloc] init];
        _rows = 0;
        _color = color;
    }
    return self;
}

-(void)setReplies:(NSArray<CLBMessageAction *> *) replies {
    for (UIButton *button in self.replyButtons) {
        [button removeFromSuperview];
    }
    
    [self.replyButtons removeAllObjects];
    
    for (CLBMessageAction *reply in replies) {
        CLBReplyButton *replyView = [self createReplyViewWithAction:reply];
        [self.replyButtons addObject:replyView];
        [self addSubview:replyView];
    }
    
    [self layoutSubviews];
}

-(CLBReplyButton *)createReplyViewWithAction:(CLBMessageAction *)reply {
    CLBReplyButton *button = [CLBReplyButton replyButtonWithAction:reply color:self.color maxWidth:self.frame.size.width];
    
    [button addTarget:self action:@selector(replyTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

-(void)layoutButtons:(NSArray *)buttons withXOrigin:(NSInteger) xOrigin yOrigin:(NSInteger) yOrigin horizontalMargin:(CGFloat) horizontalMargin verticalMargin:(CGFloat) verticalMargin {
    for (NSInteger i = buttons.count - 1; i >= 0; i--) {
        UIButton *button = buttons[i];
        CGFloat x = xOrigin - (button.frame.size.width + horizontalMargin);
        CGFloat y = yOrigin + verticalMargin;
        CGFloat width = button.frame.size.width;
        CGFloat height = button.frame.size.height;
        
        button.frame = CGRectMake(x, y, width, height);
        
        xOrigin = x;
    }
}

-(CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(size.width, self.rows * kButtonHeight + self.rows * kButtonVerticalMargin);
}

-(void)replyTapped:(CLBReplyButton *)sender {
    if (self.delegate) {
        [self.delegate repliesView:self didSelectReply:sender.action];
    }
}

-(void)layoutSubviews {
    NSMutableArray *currentRow = [[NSMutableArray alloc] init];
    NSInteger currentWidth = 0;
    NSInteger row = 0;
    CGFloat y = 0;
    
    for (int i = 0; i < self.replyButtons.count; i++) {
        CLBReplyButton *button = self.replyButtons[i];
        NSInteger buttonWidth = button.frame.size.width + kButtonHorizontalMargin;
        y = row * kButtonHeight + row * kButtonVerticalMargin;
        
        if ((currentWidth + buttonWidth) > self.frame.size.width) {
            [self layoutButtons:currentRow withXOrigin:self.frame.size.width yOrigin:y horizontalMargin:kButtonHorizontalMargin verticalMargin:kButtonVerticalMargin];
            currentWidth = 0;
            [currentRow removeAllObjects];
            row++;
        }
        
        [currentRow addObject:button];
        currentWidth += buttonWidth;
    }
    
    if (currentRow.count > 0) {
        y = row * kButtonHeight + row * kButtonVerticalMargin;
        [self layoutButtons:currentRow withXOrigin:self.frame.size.width yOrigin:y horizontalMargin:kButtonHorizontalMargin verticalMargin:kButtonVerticalMargin];
    }
    
    self.rows = row + 1;
}

@end
