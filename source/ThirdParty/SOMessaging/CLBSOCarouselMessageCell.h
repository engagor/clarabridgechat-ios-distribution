//
//  CLBSOCarouselMessageCell.h
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBSOMessageCell.h"
#import "CLBSOMessage.h"

@interface CLBSOCarouselMessageCell : CLBSOMessageCell

@property (readonly) CGSize cellSize;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier sizeCache:(NSMutableDictionary *)sizeCache scrollCache:(NSMutableDictionary *)scrollCache;

/**
 *  Calculates the size of all message items and returns the largest size to be applied to all carousel cells
 */
+(CGSize)calculateSizeForMessage:(id<CLBSOMessage>)message withFrame:(CGRect)frame imageSize:(CGSize)imageSize maxWidth:(CGFloat)maxWidth;

@end
