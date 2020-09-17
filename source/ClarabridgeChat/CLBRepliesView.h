//
//  CLBRepliesView.h
//  ClarabridgeChat
//
//  Copyright © 2016 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLBMessageAction.h"

@class CLBRepliesView;

@protocol CLBRepliesViewDelegate <NSObject>

-(void)repliesView:(CLBRepliesView *) view didSelectReply:(CLBMessageAction *)reply;

@end

@interface CLBRepliesView : UIView

@property(weak) id<CLBRepliesViewDelegate> delegate;

-(instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color;

-(void)setReplies:(NSArray<CLBMessageAction *> *) replies;

@end
