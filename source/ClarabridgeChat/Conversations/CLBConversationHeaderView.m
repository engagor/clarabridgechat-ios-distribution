//
//  CLBConversationHeaderView.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBConversationHeaderView.h"
#import "CLBLocalization.h"
#import "CLBUtility.h"

static const UIEdgeInsets kLabelInsets = {12, 10, 0, 12};
static const CGFloat kPadding = 20.0;
static const CGFloat kLabelLineSpacing = 2.0;
static const CGFloat kLabelParagraphSpacing = 7.0;
static const CGFloat kFontSize = 12.0;

@interface CLBConversationHeaderView()

@property UILabel* textLabel;
@property UIColor *accentColor;

@end

@implementation CLBConversationHeaderView

- (instancetype)init {
    return [self initWithColor:CLBDefaultAccentColor()];
}

- (instancetype) initWithColor:(UIColor *)color {
    self = [super init];
    if (self) {
        self.accentColor = color;
        [self initTextLabel];

        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(void)initTextLabel {
    _textLabel = [[UILabel alloc] init];
    _textLabel.numberOfLines = 0;
    [self updateHeaderWithType:CLBConversationHeaderTypeConversationStart];

    [self addSubview:_textLabel];
}

-(void)updateHeaderWithType:(CLBConversationHeaderType) headerType {
    if (headerType == CLBConversationHeaderTypeLoadMore) {
        [self updateHeaderWithTypeLoadMore];
    } else if (headerType == CLBConversationHeaderTypeLoading) {
        [self updateHeaderWithTypeLoading];
    } else {
        [self updateHeaderWithTypeConversationStart];
    }
}

-(void)updateHeaderWithTypeLoadMore {
    self.type = CLBConversationHeaderTypeLoadMore;

    self.textLabel.textColor = self.accentColor;
    NSString *text = [NSString stringWithString:[CLBLocalization localizedStringForKey:@"Show more..."]];
    self.textLabel.attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSParagraphStyleAttributeName: [self paragraphStyleWithLineSpacing:kLabelLineSpacing
                                                                                                                                                   paragraphSpacing:0],
                                                                                                     NSFontAttributeName: [UIFont italicSystemFontOfSize: kFontSize]}];
    self.textLabel.textAlignment = NSTextAlignmentCenter;
}

-(void)updateHeaderWithTypeLoading {
    self.type = CLBConversationHeaderTypeLoading;

    self.textLabel.textColor = CLBLightGrayColor();
    NSString *text = [NSString stringWithString:[CLBLocalization localizedStringForKey:@"Retrieving history..."]];
    self.textLabel.attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSParagraphStyleAttributeName: [self paragraphStyleWithLineSpacing:kLabelLineSpacing
                                                                                                                                                   paragraphSpacing:0],
                                                                                                                 NSFontAttributeName: [UIFont italicSystemFontOfSize: kFontSize]}];

    self.textLabel.textAlignment = NSTextAlignmentCenter;
}

-(void)updateHeaderWithTypeConversationStart {
    self.type = CLBConversationHeaderTypeConversationStart;

    self.textLabel.font = [UIFont systemFontOfSize:kFontSize];
    self.textLabel.textColor = CLBDarkGrayColor(NO);
    NSString *text = [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"This is the start of your conversation with the %@ team. We'll stay in touch to help you get the most out of your app.\nFeel free to leave us a message about anything that’s on your mind. We’ll get back to your questions, suggestions or anything else as soon as we can."], CLBGetAppDisplayName()];
    self.textLabel.attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSParagraphStyleAttributeName : [self paragraphStyleWithLineSpacing:kLabelLineSpacing
                                                                                                                                paragraphSpacing:kLabelParagraphSpacing] }];
    // Align text in the center if iPad
    self.textLabel.textAlignment = [self isIpad] ? NSTextAlignmentCenter : NSTextAlignmentNatural;
}

- (NSMutableParagraphStyle *)paragraphStyleWithLineSpacing:(CGFloat) lineSpacing paragraphSpacing:(CGFloat) paragraphSpacing {
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineSpacing = lineSpacing;
    paragraphStyle.paragraphSpacing = paragraphSpacing;
    return paragraphStyle;
}

-(BOOL)isIpad {
    return CLBIsIpad();
}

-(void)sizeToFit {
    [self sizeToFitWithInsets:[self insets]];
}

-(void)sizeToFitWithInsets:(UIEdgeInsets) insets {
    CGSize labelSize = [self.textLabel sizeThatFits:CGSizeMake(self.bounds.size.width - insets.left - insets.right, CGFLOAT_MAX)];


    CGRect frame = self.frame;
    frame.size.height = labelSize.height + insets.top + insets.bottom;
    self.frame = frame;

    self.textLabel.frame = CGRectMake(insets.left,
                                      insets.top,
                                      self.bounds.size.width - insets.left - insets.right,
                                      labelSize.height);
    [self.textLabel setCenter:self.center];
}

-(UIEdgeInsets)insets {
    UIEdgeInsets insets = kLabelInsets;
    if(self.type == CLBConversationHeaderTypeLoadMore || self.type == CLBConversationHeaderTypeLoading) {
        insets.top = insets.top + kPadding;
    }
    return insets;
}

@end
