//
//  CLBInAppNotificationView.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBInAppNotificationView.h"
#import "CLBUtility.h"
#import "CLBMessage.h"
#import "CLBLocalization.h"
#import "CLBXCharacterView.h"

const CGFloat CLBInAppNotificationViewHeight = 80;

static const CGFloat nameFontSize = 12;
static const CGFloat contentFontSize = 15;

static const CGFloat gradientMaskWidth = 30;

static const CGFloat outerPadding = 12;
static const CGFloat leftAreaWidthNoImage = 12;
static const CGFloat rightAreaWidth = 40;
static const CGFloat avatarSize = 35;
static const CGFloat leftAreaWidth = avatarSize + 2 * outerPadding;

static const CGFloat topPadding = 9;//# of pixels to move down from top of view.
static const CGFloat nameAndContentPadding = 5;//# of pixels to move content label back up because of UILabels default padding.

@interface CLBInAppNotificationView()

@property UIImageView* avatar;
@property UILabel* name;
@property UILabel* content;
@property UIView* cancelContainer;
@property CLBXCharacterView* cancel;
@property UIView* textContainer;
@property BOOL roundImage;

@end

@implementation CLBInAppNotificationView

- (instancetype)init {
    return [self initWithMessage:nil avatar:nil target:nil action:nil];
}

-(instancetype)initWithMessage:(CLBMessage*)message avatar:(UIImage*)avatarImage target:(id)target action:(SEL)action {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:28.0f/255.0f
                                               green:28.0f/255.0f
                                                blue:28.0f/255.0f
                                               alpha:1.0f];
        [self setAlpha:0.97];

        self.textContainer = [UIView new];
        [self addSubview:self.textContainer];

        [self initName:message.displayName];

        NSString *displayString =  message.text;
        NSString *trimmed = [displayString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if([trimmed length] == 0) {
            if(message.actions) {
                displayString = [message.actions.firstObject text];
            }
        }
        [self initContent:displayString];

        [self initCancel];
        if(target && action){
            [self.cancelContainer addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:target action:action]];
        }

        if(avatarImage){
            _roundImage = YES;
            [self initAvatar:avatarImage];
        }else{
            _roundImage = NO;

            UIImage *appIcon;
            NSArray* iconNames = [[NSBundle mainBundle] infoDictionary][@"CFBundleIcons"][@"CFBundlePrimaryIcon"][@"CFBundleIconFiles"];
            if(iconNames && iconNames.count > 0){
                appIcon = [UIImage imageNamed: iconNames[0]];
            }
            [self initAvatar:appIcon];
        }
    }
    return self;
}

-(void)animateAvatarAndLabel {
    self.content.transform = CGAffineTransformMakeTranslation(-self.bounds.size.width, 0);
    self.name.transform = CGAffineTransformMakeTranslation(-self.bounds.size.width, 0);
    self.content.hidden = NO;
    self.name.hidden = NO;

    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseOut;

    [UIView animateWithDuration:0.4
                          delay:0.10
                        options:options
                     animations:^{
                         self.avatar.transform = CGAffineTransformIdentity;
                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.4
                                               delay:0
                              usingSpringWithDamping:0.7
                               initialSpringVelocity:1.0
                                             options:options
                                          animations:^{
                                              self.content.transform = CGAffineTransformIdentity;
                                              self.name.transform = CGAffineTransformIdentity;
                                          } completion:nil];
                     }];
}

-(void)initName:(NSString*)name {
    self.name = [[UILabel alloc] init];
    [self.name setAdjustsFontSizeToFitWidth:NO];
    self.name.numberOfLines = 1;
    self.name.lineBreakMode = NSLineBreakByTruncatingTail;
    self.name.font = [UIFont systemFontOfSize:nameFontSize weight:UIFontWeightLight];
    [self.name setAlpha:0.7];
    [self.name setTextColor:[UIColor whiteColor]];
    self.name.hidden = YES;

    if(name && name.length > 0){
        self.name.text = name;
    }else{
        self.name.text = [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"%@ Team"], CLBGetAppDisplayName()];
    }

    [self.textContainer addSubview:self.name];
}

-(void)initContent:(NSString*)content {
    self.content = [[UILabel alloc] init];
    self.content.text = content;
    self.content.numberOfLines = 2;
    [self.content setAdjustsFontSizeToFitWidth:NO];
    self.content.lineBreakMode = NSLineBreakByTruncatingTail;
    self.content.font = [UIFont systemFontOfSize:contentFontSize];
    [self.content setTextColor:[UIColor whiteColor]];
    self.content.hidden = YES;
    [self.textContainer addSubview:self.content];
}

-(void)initCancel {
    self.cancelContainer = [UIView new];
    [self addSubview:self.cancelContainer];

    self.cancel = [[CLBXCharacterView alloc] initWithFrame:CGRectMake(0,0,13,13)];
    self.cancel.contentMode = UIViewContentModeCenter;
    [self.cancel setAlpha:0.7];

    [self.cancelContainer addSubview:self.cancel];
}

-(void)initAvatar:(UIImage*)image {
    self.avatar = [[UIImageView alloc] initWithImage:image];

    self.avatar.clipsToBounds = YES;
    self.avatar.contentMode = UIViewContentModeScaleAspectFit;

    self.avatar.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [self addSubview:self.avatar];
}

-(void)layoutSubviews {
    [super layoutSubviews];

    CGFloat avatarWidth = self.avatar.image ? leftAreaWidth : leftAreaWidthNoImage;
    CGFloat maxTextWidth = self.bounds.size.width - avatarWidth - rightAreaWidth;

    [self layoutAvatar:avatarWidth];
    [self layoutTextContainerWithAvatarWidth:avatarWidth maxTextWidth:maxTextWidth];
    [self layoutNameLabelWithMaxTextWidth:maxTextWidth];
    [self layoutContentLabelWithMaxTextWidth:maxTextWidth];
    [self layoutCancelButton];
}

-(void)layoutAvatar:(CGFloat)avatarWidth {
    self.avatar.frame = CGRectMake(outerPadding, (CLBInAppNotificationViewHeight-avatarSize)/2, avatarSize, avatarSize);
    if(self.roundImage){
        self.avatar.layer.cornerRadius = avatarSize / 2;
    }
}

-(void)layoutTextContainerWithAvatarWidth:(CGFloat)avatarWidth maxTextWidth:(CGFloat)maxTextWidth {
    self.textContainer.frame = CGRectMake(avatarWidth - gradientMaskWidth, 0, maxTextWidth + gradientMaskWidth, CLBInAppNotificationViewHeight);

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.textContainer.bounds;
    gradient.colors = @[(id)[[UIColor clearColor] CGColor],
                       (id)[[UIColor blackColor] CGColor]];
    gradient.startPoint = CGPointMake(0, 1.0);
    gradient.endPoint = CGPointMake(gradientMaskWidth / self.textContainer.bounds.size.width, 1.0);
    gradient.masksToBounds = NO;
    self.textContainer.layer.mask = gradient;
}

-(void)layoutNameLabelWithMaxTextWidth:(CGFloat)maxTextWidth {
    CGAffineTransform transform = self.name.transform;
    self.name.transform = CGAffineTransformIdentity;
    self.name.frame = CGRectMake(gradientMaskWidth , topPadding, maxTextWidth, CLBInAppNotificationViewHeight*0.3);
    self.name.transform = transform;
}

-(void)layoutContentLabelWithMaxTextWidth:(CGFloat)maxTextWidth {
    CGAffineTransform transform = self.content.transform;
    self.content.transform = CGAffineTransformIdentity;
    self.content.frame = CGRectMake(gradientMaskWidth, self.name.frame.size.height + nameAndContentPadding, maxTextWidth, CLBInAppNotificationViewHeight*0.7);
    [self.content sizeToFit];

    self.content.transform = transform;
}

-(void)layoutCancelButton {
    self.cancelContainer.frame = CGRectMake(self.bounds.size.width - rightAreaWidth, 0 , rightAreaWidth, self.bounds.size.height);

    self.cancel.transform = CGAffineTransformIdentity;
    self.cancel.frame = CGRectMake(self.cancelContainer.bounds.size.width/2 - self.cancel.bounds.size.width + 5, (CLBInAppNotificationViewHeight - self.cancel.bounds.size.height)/2, self.cancel.bounds.size.width, self.cancel.bounds.size.height);
}

@end
