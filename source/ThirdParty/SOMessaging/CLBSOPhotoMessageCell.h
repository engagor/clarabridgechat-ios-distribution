//
//  SOPictureMessageCell.h
//  ClarabridgeChat
//
//  Created by Mike on 2014-06-17.
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBSOTextMessageCell.h"

@interface CLBSOPhotoMessageCell : CLBSOTextMessageCell

@property (strong, nonatomic) UIImageView *mediaImageView;

-(void)reloadImage:(BOOL)loadFromNetwork;
-(void)reloadImage;

@end
