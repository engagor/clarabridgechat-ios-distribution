//
//  CLBReplyButton.h
//  ClarabridgeChat
//

#import <UIKit/UIKit.h>
#import "CLBMessageAction.h"

@interface CLBReplyButton : UIButton

@property CLBMessageAction *action;

+(CLBReplyButton *)replyButtonWithAction:(CLBMessageAction *)action color:(UIColor *)color maxWidth:(CGFloat) maxWidth;

@end
