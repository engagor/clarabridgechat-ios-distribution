//
//  CLBPhotoConfirmationViewController.h
//  ClarabridgeChat
//
//  Copyright © 2017 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CLBPhotoConfirmationDelegate

-(void)userDidConfirmPhoto:(UIImage *)image;

@end

@interface CLBPhotoConfirmationViewController : UIViewController

-(instancetype)initWithImage:(UIImage *)image title:(NSString *)title;

@property(weak) id<CLBPhotoConfirmationDelegate> delegate;

@end
