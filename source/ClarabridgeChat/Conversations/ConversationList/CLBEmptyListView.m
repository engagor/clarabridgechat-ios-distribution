//
//  CLBEmptyListView.m
//  ClarabridgeChat
//
//  Created by Thaciana Lima on 25/05/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBEmptyListView.h"
#import "CLBUtility.h"

@interface CLBEmptyListView ()

@property (nonatomic) UILabel *label;

@end

@implementation CLBEmptyListView

- (instancetype)initWithText:(nonnull NSString *)text {
    self = [super init];
    if (!self) return nil;

    // Label
    _label = [[UILabel alloc] init];
    _label.textColor = CLBDarkGrayColor(NO);
    _label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];

    // Add Label to View
    [self addSubview:_label];

    // Label Contraints
    _label.translatesAutoresizingMaskIntoConstraints = NO;
    [_label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
    [_label.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;

    // Set Text to Label
    _label.text = text;
    [_label sizeToFit];

    return self;
}

@end
