//
//  CLBWebviewViewController.h
//  ClarabridgeChat
//
//  Copyright © 2017 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLBMessageAction.h"

@interface CLBWebviewViewController : UIViewController

-(instancetype)initWithAction:(CLBMessageAction *)action;

@end
