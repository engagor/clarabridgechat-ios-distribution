//
//  CLBActionButton.m
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBActionButton.h"

static const CGFloat kActionButtonCornerRadius = 9;

@implementation CLBActionButton

-(instancetype)init {
    self = [super init];
    if (self) {
        self.layer.cornerRadius = kActionButtonCornerRadius;
    }
    return self;
}

@end
