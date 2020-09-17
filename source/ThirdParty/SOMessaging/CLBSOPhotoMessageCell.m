//
//  SOPictureMessageCell.m
//  ClarabridgeChat
//
//  Created by Mike on 2014-06-17.
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBSOPhotoMessageCell.h"
#import "ClarabridgeChat+Private.h"
#import "CLBImageLoader.h"
#import "CLBUtility.h"
#import "CLBFileUploadMessage.h"
#import "CLBLocalization.h"
#import "CLBRoundedRectView.h"

static NSString* const kCameraIcon = @"";
long long const CLBAutomaticDownloadLimit = 2 * 1024 * 1024;

@interface CLBSOPhotoMessageCell()

@property UIView* dimOverlay;
@property UIActivityIndicatorView* activityIndicator;
@property UILabel* imagePlaceholderLabel;
@property UIView* progressOverlay;
@property CAGradientLayer* progressOverlayMask;

@end

@implementation CLBSOPhotoMessageCell

-(void)dealloc {
    [self stopWatchingProgressNotifications];
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier vendingMachine:(CLBTextViewVendingMachine *)vendingMachine {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier vendingMachine:vendingMachine];
    
    if (self) {
        [self initMediaImageView];
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:CLBActivityIndicatorViewStyleWhite()];
        [_mediaImageView addSubview:_activityIndicator];
        
        _imagePlaceholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
        _imagePlaceholderLabel.textAlignment = NSTextAlignmentCenter;
        _imagePlaceholderLabel.numberOfLines = 3;
        _imagePlaceholderLabel.font = [UIFont systemFontOfSize:14];
        [_mediaImageView addSubview:_imagePlaceholderLabel];
        
        [self updateImagePlaceholderLabelText:[self retryText]];
        
        _progressOverlay = [[UIView alloc] initWithFrame:self.mediaImageView.bounds];
        _progressOverlay.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _progressOverlay.backgroundColor = [UIColor whiteColor];
        [_mediaImageView addSubview:_progressOverlay];
        
        _progressOverlayMask = [CAGradientLayer layer];
        _progressOverlayMask.colors = @[(id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
                                        (id)[UIColor colorWithWhite:0.0 alpha:0.5].CGColor,
                                        (id)[UIColor colorWithWhite:0.0 alpha:0.5].CGColor];
        _progressOverlayMask.locations = @[ @0.0, @0.12, @1.0 ];
        _progressOverlayMask.startPoint = CGPointMake(0.0, 0.5);
        _progressOverlayMask.endPoint = CGPointMake(1.0, 0.5);
        _progressOverlayMask.anchorPoint = CGPointZero;
        _progressOverlay.layer.mask = _progressOverlayMask;
    }
    
    return self;
}

-(void)prepareForReuse {
    [super prepareForReuse];
    
    [self stopWatchingProgressNotifications];
    [self.activityIndicator stopAnimating];
    self.imagePlaceholderLabel.hidden = YES;
}

-(void)initMediaImageView {
    _mediaImageView = [[UIImageView alloc] init];
    
    if (!CGSizeEqualToSize(self.mediaImageViewSize, CGSizeZero)) {
        CGRect frame = _mediaImageView.frame;
        frame.size = self.mediaImageViewSize;
        _mediaImageView.frame = frame;
    }
    
    _mediaImageView.contentMode = UIViewContentModeScaleAspectFill;
    _mediaImageView.clipsToBounds = YES;
    _mediaImageView.backgroundColor = [UIColor clearColor];
    _mediaImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMediaTapped:)];
    [_mediaImageView addGestureRecognizer:tap];
    
    _dimOverlay = [[UIView alloc] initWithFrame:self.mediaImageView.bounds];
    _dimOverlay.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _dimOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.04];
    
    [_mediaImageView addSubview:_dimOverlay];
    
    [self.containerView addSubview:_mediaImageView];
}

-(void)layoutContent {
    [super layoutContentWithFixedWidth:self.mediaImageViewSize.width];
    
    [self reloadImage];
    
    CGRect frame = self.bubbleView.frame;
    
    NSString *trimmedText = [self.message.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if([trimmedText length] > 0 || (self.message.actions.count > 0 && ![self hasReplyActions])) {
        frame.size.width = MAX(self.mediaImageViewSize.width, frame.size.width);
        frame.size.height += self.mediaImageViewSize.height;
    } else {
        frame.size = self.mediaImageViewSize;
    }
    
    self.mediaImageView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, self.mediaImageViewSize.height);
    
    self.progressOverlayMask.frame = self.mediaImageView.bounds;
    self.activityIndicator.center = CGPointMake(self.mediaImageView.bounds.size.width / 2, self.mediaImageView.bounds.size.height / 2);
    self.imagePlaceholderLabel.center = self.activityIndicator.center;
    
    self.bubbleView.frame = frame;
    self.bubbleView.backgroundColor = self.bubbleColor;
    
    [self adjustContentBelowFrame:self.mediaImageView.frame];
}

-(void)adjustCell {
    [super adjustCell];
    
    if(self.message.isFromCurrentUser){
        self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        self.mediaImageView.backgroundColor = [self.accentColor colorWithAlphaComponent:0.5];
        self.imagePlaceholderLabel.textColor = [UIColor whiteColor];
    }else{
        self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        self.mediaImageView.backgroundColor = [CLBExtraLightGrayColor(NO) colorWithAlphaComponent:0.5];
        self.imagePlaceholderLabel.textColor = CLBDarkGrayColor(YES);
    }
    
    //Masking mediaImageView with balloon image
    CLBRoundedRectView *maskView = [[CLBRoundedRectView alloc] initWithFrame:self.bubbleView.bounds];
    maskView.flatCorners = self.bubbleView.flatCorners;
    maskView.backgroundColor = [UIColor colorWithWhite:0.f alpha:1.f];
    self.mediaImageView.maskView = maskView;
    [self.mediaImageView setNeedsDisplay];
}

-(void)updateProgressAnimated:(BOOL)animated {
    CGPoint position = CGPointMake(self.message.progress*self.mediaImageView.frame.size.width, 0);
    if(animated){
        CGFloat duration = 3.0;
        CLBEnsureMainThread(^{
            [UIView animateWithDuration:duration animations:^{
                [CATransaction begin];
                [CATransaction setAnimationDuration:duration];
                
                self.progressOverlayMask.position = position;
                [CATransaction commit];
            }];
        });
    }else{
        self.progressOverlayMask.position = position;
    }
}

-(void)updateProgress {
    [self updateProgressAnimated:YES];
}

- (void)handleMediaTapped:(UITapGestureRecognizer *)tap {
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageCellDidTapMedia:)]) {
        [self.delegate messageCellDidTapMedia:self];
    }
}

-(void)watchProgressNotifications {
    [self stopWatchingProgressNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress) name:CLBFileUploadMessageProgressDidChangeNotification object:self.message];
}

-(void)stopWatchingProgressNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)reloadImage {
    BOOL loadFromNetwork = [self.message.mediaSize longLongValue] > 0 && [self.message.mediaSize longLongValue] <= CLBAutomaticDownloadLimit;
    [self reloadImage:loadFromNetwork];
}

-(void)reloadImage:(BOOL)loadFromNetwork {
    id<CLBSOMessage> message = self.message;
    CLBImageLoader* imageLoader = [ClarabridgeChat avatarImageLoader];
    UIImage* image = message.image;
    
    self.imagePlaceholderLabel.hidden = YES;
    
    if(image){
        if(message.failed){
            self.progressOverlay.hidden = YES;
        }else{
            self.progressOverlay.hidden = NO;
            [self updateProgressAnimated:NO];
            [self watchProgressNotifications];
        }
        
        self.mediaImageView.image = image;
    }else{
        self.progressOverlay.hidden = YES;
        image = [imageLoader cachedImageForUrl:message.mediaUrl];
        self.mediaImageView.image = image;
        
        if(!image){
            if (loadFromNetwork) {
                [self.activityIndicator startAnimating];
                [imageLoader loadImageForUrl:message.mediaUrl withCompletion:^(UIImage* image) {
                    // If cell has not been recycled
                    if(message == self.message){
                        [self.activityIndicator stopAnimating];
                        if(image){
                            self.mediaImageView.image = image;
                        }else{
                            [self updateImagePlaceholderLabelText:[self retryText]];
                        }
                    }
                }];
            } else {
                [self updateImagePlaceholderLabelText:[self largeImageText]];
            }
        }
    }
}

-(void)updateImagePlaceholderLabelText:(NSString *)text {
    UIFont* symbolFont = [UIFont fontWithName:@"ios7-icon" size:35];
    
    if(symbolFont){
        NSMutableAttributedString* str = [[NSMutableAttributedString alloc] initWithString:text];
        [str setAttributes:@{ NSFontAttributeName : symbolFont } range:NSMakeRange(0, 1)];
        self.imagePlaceholderLabel.attributedText = str;
    }else{
        self.imagePlaceholderLabel.text = text;
    }
    self.imagePlaceholderLabel.hidden = NO;
}

-(NSString *)largeImageText {
    long long size = [self.message.mediaSize longLongValue];
    NSString *sizeText = @"";
    
    if (size > 0) {
        NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
        sizeText = [NSString stringWithFormat:@" %@", [formatter stringFromByteCount:size]];
    }
    
    return [self loadImageFullText:[NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"Tap to view%@ image"], sizeText]];
}

-(NSString *)retryText {
    return [self loadImageFullText:[CLBLocalization localizedStringForKey:@"Tap to reload image"]];
}

-(NSString *)loadImageFullText:(NSString *)text {
    NSString* labelTitle = [CLBLocalization localizedStringForKey:@"Preview not available"];
    return [NSString stringWithFormat:@"%@\n%@\n%@", kCameraIcon, labelTitle, text];
}

@end
