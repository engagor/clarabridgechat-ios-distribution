//
//  SOVideoMessageCell.h
//  ClarabridgeChat
//
//  Created by Mike on 2014-06-17.
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBSOPhotoMessageCell.h"

@interface CLBSOVideoMessageCell : CLBSOPhotoMessageCell

@property (strong, nonatomic) UIView *mediaOverlayView; // For video only

@end
