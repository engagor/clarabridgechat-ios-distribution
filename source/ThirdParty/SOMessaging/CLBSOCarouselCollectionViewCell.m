//
//  CLBSOCarouselCollectionViewCell.m
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBSOCarouselCollectionViewCell.h"
#import "CLBMessageItemView.h"

@implementation CLBSOCarouselCollectionViewCell

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        _messageItemView = [[CLBMessageItemView alloc] initWithFrame:self.contentView.frame];
        [self.contentView addSubview:_messageItemView];
    }
    
    return self;
}

@end
