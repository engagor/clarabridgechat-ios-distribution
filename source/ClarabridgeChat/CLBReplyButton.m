//
//  CLBReplyButton.m
//  ClarabridgeChat
//

#import "CLBReplyButton.h"
#import "CLBMessageAction.h"
#import "CLBImageLoader.h"
#import "ClarabridgeChat+Private.h"
#import "CLBUtility.h"

static const CGFloat kButtonHeight = 40;
static const CGFloat kButtonHorizontalMargin = 7;
static const CGFloat kCornerRadius = 9;

@interface CLBReplyButton ()

@property UIColor *baseColor;
@property UIColor *saturatedColor;
@property UIImageView *iconImageView;

@end

@implementation CLBReplyButton

+(CLBReplyButton *)replyButtonWithAction:(CLBMessageAction *)action color:(UIColor *)color maxWidth:(CGFloat) maxWidth {
    CLBReplyButton *button = [super buttonWithType:UIButtonTypeCustom];
    [button setTitle:action.text forState:UIControlStateNormal];
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    button.baseColor = color;
    button.saturatedColor = CLBSaturatedColorForColor(color);
    CGFloat imageViewSize = kButtonHeight * .8f;
    CGFloat imageOffset = (kButtonHeight - imageViewSize) / 2;
    CGFloat textOffset = imageViewSize + imageOffset;
    [button sizeToFit];
    BOOL hasIcon = [CLBMessageActionTypeLocationRequest isEqualToString:action.type] || (action.iconUrl && [[action.iconUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] > 0);
    if (hasIcon) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(imageOffset, imageOffset, imageViewSize, imageViewSize)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [button addSubview:imageView];
        button.iconImageView = imageView;
        button.titleEdgeInsets = UIEdgeInsetsMake(0, textOffset, 0, 0);
        if ([CLBMessageActionTypeLocationRequest isEqualToString:action.type]) {
            UIImage *image = [ClarabridgeChat getImageFromResourceBundle:@"locationIcon"];
            imageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            imageView.tintColor = color;
        } else {
            CLBImageLoader* imageLoader = [ClarabridgeChat avatarImageLoader];
            UIImage *image = [imageLoader cachedImageForUrl:action.iconUrl];
            if(image){
                imageView.image = image;
            } else {
                [imageLoader loadImageForUrl:action.iconUrl withCompletion:^(UIImage* image) {
                    imageView.image = image;
                }];
            }
        }
    }
    if (hasIcon) {
        CGRect buttonFrame = button.frame;
        buttonFrame.size.width += textOffset;
        button.frame = buttonFrame;
    }
    
    button.layer.cornerRadius = kCornerRadius;
    CGFloat width = MAX(button.frame.size.width + kButtonHorizontalMargin * 2, 60);
    if (width > maxWidth) {
        width = maxWidth - kButtonHorizontalMargin * 2;
    }
    button.frame = CGRectMake(0, 0, width, kButtonHeight);
    
    button.backgroundColor = button.saturatedColor;
    
    [button setTitleColor:button.baseColor forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    button.layer.borderColor = [color CGColor];
    button.layer.borderWidth = 1;
    
    button.action = action;
    
    return button;
}

-(void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.backgroundColor = highlighted ? self.baseColor : self.saturatedColor;
    
    if ([self.action.type isEqualToString:CLBMessageActionTypeLocationRequest]) {
        self.iconImageView.tintColor = highlighted ? self.saturatedColor : self.baseColor;
    }
}

@end
