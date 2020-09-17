//
//  CLBConversationHeaderView.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CLBConversationHeaderType) {
    CLBConversationHeaderTypeConversationStart = 0,
    CLBConversationHeaderTypeLoading = 1,
    CLBConversationHeaderTypeLoadMore = 2
};

@interface CLBConversationHeaderView : UIView

-(instancetype)initWithColor:(UIColor *)color;
-(void)updateHeaderWithType:(CLBConversationHeaderType) headerType;

@property CLBConversationHeaderType type;

@end
