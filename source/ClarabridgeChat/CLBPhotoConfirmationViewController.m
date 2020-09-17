//
//  CLBPhotoConfirmationAlert.m
//  ClarabridgeChat
//
//  Copyright © 2017 Smooch Technologies. All rights reserved.
//

#import "CLBPhotoConfirmationViewController.h"
#import "CLBLocalization.h"
#import "CLBUtility.h"

static const CGFloat kButtonHeight = 44;
static const CGFloat kButtonFontSize = 16;
static const CGFloat kAlertSize = 300;
static const CGFloat kImagePadding = 24;
static const CGFloat kCornerRadius = 9;
static const CGFloat kBorderWidth = .5f;

@interface CLBPhotoConfirmationViewController ()

@property(nonatomic, strong) UIView *containerView;
@property(nonatomic, strong) UIVisualEffectView *blurEffectView;
@property(nonatomic, strong) UIButton *okButton;
@property(nonatomic, strong) UIButton *cancelButton;
@property(nonatomic, strong) UILabel *titleLabel;
@property(copy) NSString *titleText;
@property(nonatomic, strong) UIImageView *imageView;
@property(nonatomic, strong) UIImage *image;
@property(nonatomic, strong) UIView *buttonsHorizontalSeparatorView;
@property(nonatomic, strong) UIView *buttonsVerticalSeparatorView;

@end

@implementation CLBPhotoConfirmationViewController

-(instancetype)initWithImage:(UIImage *)image title:(NSString *)title {
    self = [self init];
    
    if (self) {
        _image = image;
        _titleText = title;
    }
    
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpContainer];
    [self setUpButtons];
    [self setUpTitle];
    [self setUpImageView];
    [self setUpSeparators];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reframeView];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self reframeView];
}

-(void)setUpContainer {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:CLBBlurEffectStyle()];
    self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    [self.view addSubview:self.containerView];
    [self.containerView addSubview:self.blurEffectView];
}

-(void)setUpButtons {
    self.okButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.okButton setTitle:[CLBLocalization localizedStringForKey:@"Send"] forState:UIControlStateNormal];
    [self.okButton addTarget:self action:@selector(confirm) forControlEvents:UIControlEventTouchUpInside];
    self.okButton.titleLabel.font = [UIFont boldSystemFontOfSize:kButtonFontSize];
    [self.cancelButton setTitle:[CLBLocalization localizedStringForKey:@"Cancel"] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:kButtonFontSize];
    [self.containerView addSubview:self.okButton];
    [self.containerView addSubview:self.cancelButton];
}

-(void)setUpTitle {
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.text = self.titleText;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.containerView addSubview:self.titleLabel];
}

-(void)setUpSeparators {
    self.buttonsHorizontalSeparatorView = [[UIView alloc] init];
    self.buttonsHorizontalSeparatorView.backgroundColor = CLBMediumGrayColor();
    self.buttonsVerticalSeparatorView = [[UIView alloc] init];
    self.buttonsVerticalSeparatorView.backgroundColor = CLBMediumGrayColor();
    [self.containerView addSubview:self.buttonsHorizontalSeparatorView];
    [self.containerView addSubview:self.buttonsVerticalSeparatorView];
}

-(void)setUpImageView {
    self.imageView = [[UIImageView alloc] initWithImage:self.image];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.containerView addSubview:self.imageView];
}

-(void)reframeView {
    [self reframeContainer];
    [self reframeTitle];
    [self reframeImage];
    [self reframeButtons];
}

-(void)reframeContainer {
    self.blurEffectView.frame = CGRectMake(0, 0, kAlertSize, kAlertSize);
    self.containerView.frame = CGRectMake(0, 0, kAlertSize, kAlertSize);
    self.containerView.center = self.view.center;
    self.containerView.layer.cornerRadius = kCornerRadius;
    self.containerView.clipsToBounds = YES;
}

-(void)reframeTitle {
    self.titleLabel.frame = CGRectMake(0, 0, self.containerView.frame.size.width, kButtonHeight);
}

-(void)reframeImage {
    CGFloat width = self.containerView.frame.size.width - kImagePadding * 2;
    CGFloat height = self.containerView.frame.size.height - self.titleLabel.frame.size.height - kButtonHeight - kImagePadding * 2;
    self.imageView.frame = CGRectMake(kImagePadding, self.titleLabel.frame.size.height + kImagePadding / 2, width, height);
    self.imageView.layer.cornerRadius = kCornerRadius;
    self.imageView.clipsToBounds = YES;
}

-(void)reframeButtons {
    CGFloat buttonsY = self.containerView.frame.size.height - kButtonHeight;
    CGFloat buttonsWidth = self.containerView.frame.size.width / 2;
    self.cancelButton.frame = CGRectMake(0, buttonsY, buttonsWidth, kButtonHeight);
    self.okButton.frame = CGRectMake(buttonsWidth, buttonsY, buttonsWidth, kButtonHeight);
    self.buttonsHorizontalSeparatorView.frame = CGRectMake(0, buttonsY - kBorderWidth, self.containerView.frame.size.width, kBorderWidth);
    self.buttonsVerticalSeparatorView.frame = CGRectMake(buttonsWidth - kBorderWidth / 2, buttonsY, kBorderWidth, kButtonHeight);
}

-(void)confirm {
    if (self.delegate) {
        [self.delegate userDidConfirmPhoto:self.image];
    }
    [self close];
}

-(void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
