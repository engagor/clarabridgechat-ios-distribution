//
//  CLBNoNetworkOverlay.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBErrorMessageOverlay.h"
#import "CLBLocalization.h"

static const CGFloat kMinHeight = 30;

@implementation CLBErrorMessageOverlay

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];

        _textLabel = [[UILabel alloc] init];
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.numberOfLines = 2;
        _textLabel.font = [UIFont systemFontOfSize:13];
        [self addSubview:_textLabel];
    }
    return self;
}

-(void)sizeToFit {
    CGSize maxSize = [self.textLabel sizeThatFits:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)];
    self.textLabel.frame = CGRectMake(0, 0, self.bounds.size.width, MAX(maxSize.height, kMinHeight));

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.textLabel.frame.size.height);
}

@end
