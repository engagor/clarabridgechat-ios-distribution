//
//  CLBImagePickerController.m
//  ClarabridgeChat
//
//  Copyright © 2015 Smooch Technologies. All rights reserved.
//

#import "CLBImagePickerController.h"

@implementation CLBImagePickerController

-(BOOL)shouldAutorotate {
    return [self.presentingViewController shouldAutorotate];
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.presentingViewController supportedInterfaceOrientations];
}

@end
