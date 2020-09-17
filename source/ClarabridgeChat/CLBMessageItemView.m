//
//  CLBMessageItemView.m
//  ClarabridgeChatTests
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBMessageItemView.h"
#import "CLBImageLoader.h"
#import "ClarabridgeChat+Private.h"
#import "CLBProgressButton.h"
#import "CLBUtility.h"
#import "CLBMessageItemViewModel.h"
#import "CLBMessageAction+Private.h"
#import "CLBLocalization.h"
#import "CLBActionButton.h"

static NSString* const kCameraIcon = @"";
static const CGFloat kLabelHorizontalPadding = 10;
static const CGFloat kLabelTopPadding = 15;
static const CGFloat kActionButtonTitleHorizontalInset = 14;

@interface CLBMessageItemView() <UIGestureRecognizerDelegate>

@property CLBMessageItemViewModel *viewModel;

// Container
@property CLBRoundedRectView *containerView;
@property CLBRoundedRectView *borderView;

// Image
@property UIActivityIndicatorView *activityIndicator;
@property UIView *dimOverlay;
@property UILabel *failureLabel;

// Title
@property UITextView *titleLabelView;

// Description
@property UITextView *descriptionLabelView;

// Actions
@property UIView *actionsContainer;

@end

@implementation CLBMessageItemView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        _borderView = [[CLBRoundedRectView alloc] initWithFrame:CGRectZero];
        [self addSubview:_borderView];
        _containerView = [[CLBRoundedRectView alloc] initWithFrame:CGRectZero];
        [self addSubview:_containerView];
        
        // Image
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _dimOverlay = [[UIView alloc] initWithFrame:CGRectZero];
        _dimOverlay.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _dimOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.04];
        [_imageView addSubview:_dimOverlay];
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:CLBActivityIndicatorViewStyleGray()];
        [_imageView addSubview:_activityIndicator];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *imageTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTap:)];
        [_imageView addGestureRecognizer:imageTapGesture];
        
        // Taken from CLBSOPhotoMessageCell
        _failureLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
        _failureLabel.textAlignment = NSTextAlignmentCenter;
        _failureLabel.numberOfLines = 2;
        _failureLabel.font = [UIFont systemFontOfSize:14];
        NSString* labelText = [CLBLocalization localizedStringForKey:@"Tap to reload image"];
        UIFont* symbolFont = [UIFont fontWithName:@"ios7-icon" size:35];
        if(symbolFont){
            NSString* fullText = [NSString stringWithFormat:@"%@\n%@", kCameraIcon, labelText];
            NSMutableAttributedString* str = [[NSMutableAttributedString alloc] initWithString:fullText];
            [str setAttributes:@{ NSFontAttributeName : symbolFont } range:NSMakeRange(0, 1)];
            _failureLabel.attributedText = str;
        }else{
            _failureLabel.text = labelText;
        }
        [_failureLabel sizeToFit];
        [_imageView addSubview:_failureLabel];
        
        [_containerView addSubview:_imageView];
        
        // Title
        _titleLabelView = [[UITextView alloc] initWithFrame:CGRectZero];
        _titleLabelView.textContainerInset = UIEdgeInsetsMake(kLabelTopPadding, kLabelHorizontalPadding, 0, kLabelHorizontalPadding);
        _titleLabelView.textContainer.lineFragmentPadding = 0;
        _titleLabelView.backgroundColor = [UIColor clearColor];
        _titleLabelView.selectable = NO;
        _titleLabelView.scrollEnabled = NO;
        UITapGestureRecognizer *titleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTextTap:)];
        titleTapGesture.delegate = self;
        [_titleLabelView addGestureRecognizer:titleTapGesture];
        
        [_containerView addSubview:_titleLabelView];
        
        // Description
        _descriptionLabelView = [[UITextView alloc] initWithFrame:CGRectZero];
        _descriptionLabelView.textContainerInset = UIEdgeInsetsMake(0, kLabelHorizontalPadding, 0, kLabelHorizontalPadding);
        _descriptionLabelView.textContainer.lineFragmentPadding = 0;
        _descriptionLabelView.backgroundColor = [UIColor clearColor];
        _descriptionLabelView.selectable = NO;
        _descriptionLabelView.scrollEnabled = NO;
        UITapGestureRecognizer *descriptionTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTextTap:)];
        descriptionTapGesture.delegate = self;
        [_descriptionLabelView addGestureRecognizer:descriptionTapGesture];
        
        [_containerView addSubview:_descriptionLabelView];
        
        // Actions
        _actionsContainer = [[UIView alloc] initWithFrame:CGRectZero];
        [_containerView addSubview:_actionsContainer];
    }
    
    return self;
}

-(void)setContent:(CLBMessageItemViewModel *)viewModel {
    self.viewModel = viewModel;
    
    [self setUpImageView];
    [self setUpTitleView];
    [self setUpDescriptionView];
    [self setUpActions];
    [self setUpContainerView];
    [self maskImageView];
}

-(void)setUpContainerView {
    self.containerView.backgroundColor = self.viewModel.backgroundColor;
    self.containerView.flatCorners = self.viewModel.flatCorners;
    self.borderView.backgroundColor = self.viewModel.actionsSeparatorColor;
    self.borderView.flatCorners = self.viewModel.flatCorners;
    
    CGFloat width = [self sizeToFitText].width;
    CGFloat borderArea = self.viewModel.borderArea;
    
    CGFloat contentHeight = CGRectGetMaxY(self.actionsContainer.frame);
    
    CGFloat preferredContentHeight = self.viewModel.preferredContentHeight - borderArea;
    
    // We want all cells to have the same content height
    if (preferredContentHeight > 0 && contentHeight < preferredContentHeight) {
        CGFloat heightDiff = preferredContentHeight - contentHeight;

        CGRect actionsContainerFrame = self.actionsContainer.frame;
        CGFloat newActionsContainerY = actionsContainerFrame.origin.y + heightDiff;
        self.actionsContainer.frame = CGRectMake(actionsContainerFrame.origin.x, newActionsContainerY, actionsContainerFrame.size.width, actionsContainerFrame.size.height);

        contentHeight += heightDiff;
    }

    self.containerView.frame = CGRectMake(borderArea / 2, borderArea / 2, width, contentHeight);
    self.borderView.frame = CGRectMake(0, 0, width + borderArea, contentHeight + borderArea);
    self.frame = self.borderView.frame;
}

-(void)setUpImageView {
    self.failureLabel.hidden = YES;
    if (self.viewModel.mediaUrl) {
        self.imageView.frame = CGRectMake(0, 0, self.viewModel.imageViewSize.width, self.viewModel.imageViewSize.height);
        self.dimOverlay.frame = self.imageView.bounds;
        self.activityIndicator.center = CGPointMake(self.imageView.bounds.size.width / 2, self.imageView.bounds.size.height / 2);
        self.imageView.hidden = NO;
        self.activityIndicator.hidden = NO;
        self.failureLabel.center = CGPointMake(self.imageView.bounds.size.width / 2, self.imageView.bounds.size.height / 2);
    } else {
        self.imageView.frame = CGRectZero;
        self.imageView.hidden = YES;
        self.activityIndicator.hidden = YES;
    }
}

-(void)maskImageView {
    CLBRoundedRectView *maskView = [[CLBRoundedRectView alloc] initWithFrame:self.containerView.bounds];
    maskView.flatCorners = self.containerView.flatCorners;
    maskView.backgroundColor = [UIColor colorWithWhite:0.f alpha:1.f];
    self.imageView.maskView = maskView;
}

-(void)loadImage {
    __weak CLBMessageItemViewModel *viewModel = self.viewModel;
    
    self.failureLabel.hidden = YES;
    self.dimOverlay.hidden = YES;
    [self.activityIndicator stopAnimating];
    
    CLBImageLoader* imageLoader = [ClarabridgeChat avatarImageLoader];
    UIImage* image = [imageLoader cachedImageForUrl:self.viewModel.mediaUrl];
    self.imageView.image = image;
    
    if (!image) {
        [self.activityIndicator startAnimating];
        self.dimOverlay.hidden = NO;
        [imageLoader loadImageForUrl:self.viewModel.mediaUrl withCompletion:^(UIImage* image) {
            // If cell has not been recycled
            if(viewModel == self.viewModel) {
                [self.activityIndicator stopAnimating];
                if (image) {
                    self.imageView.image = image;
                    self.dimOverlay.hidden = YES;
                } else {
                    self.failureLabel.hidden = NO;
                }
            }
        }];
    }
}

-(void)handleImageTap:(UITapGestureRecognizer *)tap {
    if (!self.imageView.image) {
        [self loadImage];
        return;
    }
    
    if ([self handleDefaultAction]) {
        return;
    }
    
    if (self.delegate) {
        [self.delegate messageItemView:self didTapImage:self.imageView.image];
    }
}

-(void)handleTextTap:(UITapGestureRecognizer *)tap {
    [self handleDefaultAction];
}

-(BOOL)handleDefaultAction {
    for (CLBMessageAction *action in self.viewModel.actions) {
        if (action.isDefault) {
            if (action.isEnabled && !action.isProcessing) {
                [self actionSelected:action];
            }
            return YES;
        }
    }
    
    return NO;
}

-(void)setUpTitleView {
    NSString *text = [self trimmedStringForString:self.viewModel.text];
    
    if (!text || [text isEqualToString:@""]) {
        self.titleLabelView.frame = CGRectMake(0, CGRectGetMaxY(self.imageView.frame), 0, 0);
    } else {
        [self setText:text onTextView:self.titleLabelView withTextColor:self.viewModel.titleTextColor accentColor:self.viewModel.accentColor font:[UIFont boldSystemFontOfSize:self.viewModel.titleFontSize]];
        CGSize titleSize = [self.titleLabelView sizeThatFits:[self sizeToFitText]];
        
        self.titleLabelView.frame = CGRectMake(0, CGRectGetMaxY(self.imageView.frame), titleSize.width, titleSize.height);
    }
}

-(void)setUpDescriptionView {
    NSString *text = [self trimmedStringForString:self.viewModel.itemDescription];
    
    if (!text || [text isEqualToString:@""]) {
        self.descriptionLabelView.frame = CGRectMake(0, CGRectGetMaxY(self.titleLabelView.frame), 0, 0);
    } else {
        [self setText:text onTextView:self.descriptionLabelView withTextColor:self.viewModel.descriptionTextColor accentColor:self.viewModel.accentColor font:[UIFont systemFontOfSize:self.viewModel.descriptionFontSize]];
        CGSize descriptionSize = [self.descriptionLabelView sizeThatFits:[self sizeToFitText]];
        
        self.descriptionLabelView.frame = CGRectMake(0, CGRectGetMaxY(self.titleLabelView.frame), descriptionSize.width, descriptionSize.height);
    }
}

-(NSString *)trimmedStringForString:(NSString *)string {
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(void)setUpActions {
    if (self.viewModel.actions.count > 0) {
        CGFloat containerWidth = [self sizeToFitText].width;
        
        int actionsContainerSubviewsCount = (int) self.actionsContainer.subviews.count;
        
        CGFloat actionsContainerHeight = self.viewModel.actionsContainerTopPadding;
        
        for (int i = 0; i < self.viewModel.actions.count; i++) {
            BOOL shouldReuseView = actionsContainerSubviewsCount > 0 && actionsContainerSubviewsCount > i * 2; // action buttons + separator views
            UIView *actionSeparatorView = shouldReuseView ? self.actionsContainer.subviews[i * 2] : nil;
            CLBActionButton *actionButton = shouldReuseView ? self.actionsContainer.subviews[i * 2 + 1] : nil;
            
            if (!actionSeparatorView) {
                actionSeparatorView =  [[UIView alloc] initWithFrame:CGRectZero];
                actionSeparatorView.backgroundColor = self.viewModel.actionsSeparatorColor;
                [self.actionsContainer addSubview:actionSeparatorView];
            }
            
            actionSeparatorView.frame = CGRectMake(self.viewModel.actionButtonSeparatorPadding, actionsContainerHeight, containerWidth - self.viewModel.actionButtonSeparatorPadding * 2, self.viewModel.actionButtonSeparatorHeight);
            
            actionsContainerHeight += actionSeparatorView.frame.size.height;
            
            if (!actionButton) {
                actionButton = [self newButton];
                [self.actionsContainer addSubview:actionButton];
            }
            
            actionButton.action = self.viewModel.actions[i];
            
            actionButton.frame = CGRectMake(0, actionsContainerHeight, containerWidth, self.viewModel.actionsButtonHeight);
            actionsContainerHeight += self.viewModel.actionsButtonHeight;
            
            actionButton.backgroundColor = self.viewModel.actionButtonBackgroundColor;
            [actionButton setTitleColor:self.viewModel.actionButtonHighlightedColor forState:UIControlStateHighlighted];
            
            if (actionButton.action.isEnabled) {
                [actionButton setTitle:actionButton.action.text forState:UIControlStateNormal];
                [actionButton setTitleColor:self.viewModel.actionButtonEnabledColor forState:UIControlStateNormal];
                actionButton.enabled = YES;
                [actionButton addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [actionButton setTitle:self.viewModel.actionButtonDisabledText forState:UIControlStateNormal];
                [actionButton setTitleColor:self.viewModel.actionButtonDisabledColor forState:UIControlStateNormal];
                actionButton.enabled = NO;
            }
            
            [actionButton setProcessing:actionButton.action.isProcessing];
        }
        
        BOOL shouldRemoveUnusedViews = actionsContainerSubviewsCount > self.viewModel.actions.count * 2; // action buttons + separator views
        
        if (shouldRemoveUnusedViews) {
            for (int i = actionsContainerSubviewsCount - 1; i >= self.viewModel.actions.count * 2; i--) {
                [self.actionsContainer.subviews[i] removeFromSuperview];
            }
        }
        
        self.actionsContainer.frame = CGRectMake(0, CGRectGetMaxY(self.descriptionLabelView.frame), containerWidth, actionsContainerHeight);
        self.actionsContainer.hidden = NO;
    } else {
        self.actionsContainer.frame = CGRectMake(0, CGRectGetMaxY(self.descriptionLabelView.frame), 0, self.viewModel.actionButtonSeparatorPadding);
        self.actionsContainer.hidden = YES;
    }
}

-(CLBActionButton*)newButton {
    CLBActionButton* button = [[CLBActionButton alloc] initWithFrame:CGRectZero activityIndicatorStyle:CLBActivityIndicatorViewStyleGray()];
    button.titleLabel.font = self.viewModel.actionButtonFont;
    [button setTitleEdgeInsets:UIEdgeInsetsMake(-2, kActionButtonTitleHorizontalInset, 0, kActionButtonTitleHorizontalInset)];
    
    return button;
}

-(CGSize)sizeToFitText {
    if (self.preferredContentWidth > 0) {
        return CGSizeMake(self.preferredContentWidth, CGFLOAT_MAX);
    }
    
    if (self.viewModel.mediaUrl) {
        return CGSizeMake(self.viewModel.imageViewSize.width, CGFLOAT_MAX);
    }
    
    return CGSizeMake(self.viewModel.messageMaxWidth, CGFLOAT_MAX);
}

-(CGFloat)preferredContentWidth {
    return self.viewModel.preferredContentWidth - self.viewModel.borderArea;
}

// Extracted from CLBTextViewVendingMachine
-(void)setText:(NSString *)text onTextView:(UITextView*)textView withTextColor:(UIColor *)textColor accentColor:(UIColor *)accentColor font:(UIFont *)font {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = self.viewModel.textLineSpacing;
    
    textView.linkTextAttributes = @{
                                    NSForegroundColorAttributeName: accentColor,
                                    NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
                                    };
    
    textView.attributedText = [[NSAttributedString alloc] initWithString:text
                                                              attributes:@{
                                                                           NSFontAttributeName : font,
                                                                           NSForegroundColorAttributeName : textColor,
                                                                           NSParagraphStyleAttributeName: paragraphStyle
                                                                           }];
}

-(void)actionButtonTapped:(CLBActionButton *)button {
    [self actionSelected:button.action];
}

-(void)actionSelected:(CLBMessageAction *)action {
    if (self.delegate) {
        [self.delegate messageItemView:self didSelectAction:action];
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
