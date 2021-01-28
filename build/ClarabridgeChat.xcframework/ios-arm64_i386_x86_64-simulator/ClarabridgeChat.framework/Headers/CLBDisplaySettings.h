//
//  CLBDisplaySettings.h
//  ClarabridgeChat
//

#import <Foundation/Foundation.h>

/**
 *  @abstract horizontal image aspect ratio
 */
extern NSString* _Nonnull const CLBImageAspectRatioHorizontal;

/**
 *  @abstract squared image aspect ratio
 */
extern NSString* _Nonnull const CLBImageAspectRatioSquare;

/**
 *  @abstract Settings to adjust a carousel layout
 */
@interface CLBDisplaySettings : NSObject

/*
 * @abstract Specifies how to display all carousel images
 *
 * @discussion Valid values are horizontal and square. May be nil
 */
@property (nullable, copy) NSString *imageAspectRatio;

@end
