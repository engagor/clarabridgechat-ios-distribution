//
//  CLBSOFileMessageCell.m
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBSOFileMessageCell.h"
#import "CLBUtility.h"
#import "CLBRoundedRectView.h"
#import "ClarabridgeChat+Private.h"
#import "CLBFileUploadMessage.h"
#import "CLBTextViewVendingMachine.h"

static const UIEdgeInsets CLBSOFileMessageCellViewPadding = { 9, 15, 9, 9 };
static const CGSize kFileIconSize = {26, 26};
static const CGFloat kCellHeight = 60;
static const CGFloat kHorizontalPadding = 10;
static const CGFloat kSeparatorHeight = 1;

@interface CLBSOFileMessageCell()

@property UIView *fileContainerView;
@property UITextView *messageTextLabel;
@property UITextView *filenameLabel;
@property UITextView *sizeLabel;
@property UIImageView *fileIcon;
@property UITapGestureRecognizer *fileTapGesture;
@property UIView *progressOverlay;
@property CAGradientLayer *progressOverlayMask;
@property CLBTextViewVendingMachine *vendingMachine;
@property UIView *separatorView;

@end

@implementation CLBSOFileMessageCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier vendingMachine:(CLBTextViewVendingMachine*)vendingMachine {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _vendingMachine = vendingMachine;
        _messageTextLabel = [vendingMachine newTextView];
        _filenameLabel = [self newTextViewWithFont:[UIFont boldSystemFontOfSize:kFontSize]];
        _sizeLabel = [self newTextViewWithFont:[UIFont systemFontOfSize:kFontSize - 2]];
        _fileIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kFileIconSize.width, kFileIconSize.height)];
        UIImage *image = [ClarabridgeChat getImageFromResourceBundle:@"paperClip"];
        _fileIcon.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        _progressOverlay = [[UIView alloc] initWithFrame:CGRectZero];
        _progressOverlay.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _progressOverlay.backgroundColor = [UIColor whiteColor];
        _progressOverlayMask = [CAGradientLayer layer];
        _progressOverlayMask.colors = @[(id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
                                        (id)[UIColor colorWithWhite:0.0 alpha:0.5].CGColor,
                                        (id)[UIColor colorWithWhite:0.0 alpha:0.5].CGColor];
        _progressOverlayMask.locations = @[ @0.0, @0.12, @1.0 ];
        _progressOverlayMask.startPoint = CGPointMake(0.0, 0.5);
        _progressOverlayMask.endPoint = CGPointMake(1.0, 0.5);
        _progressOverlayMask.anchorPoint = CGPointZero;
        _progressOverlay.layer.mask = _progressOverlayMask;
        _fileContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        _fileContainerView.backgroundColor = [UIColor clearColor];
        _separatorView = [[UIView alloc] initWithFrame:CGRectZero];
        
        [self.containerView addSubview:_messageTextLabel];
        [self.containerView addSubview:_separatorView];
        [self.containerView addSubview:_fileContainerView];
        [self.fileContainerView addSubview:_filenameLabel];
        [self.fileContainerView addSubview:_sizeLabel];
        [self.fileContainerView addSubview:_fileIcon];
        [self.containerView addSubview:_progressOverlay];
        
        _fileTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fileMessageTapped)];
    }
    
    return self;
}

-(UITextView *)newTextViewWithFont:(UIFont *)font {
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectZero];
    textView.textContainerInset = UIEdgeInsetsZero;
    textView.backgroundColor = [UIColor clearColor];
    textView.textContainer.maximumNumberOfLines = 1;
    textView.textContainer.lineBreakMode = NSLineBreakByTruncatingMiddle;
    textView.font = font;
    textView.scrollEnabled = NO;
    textView.editable = NO;
    textView.selectable = NO;
    textView.userInteractionEnabled = NO;
    
    return textView;
}

-(void)layoutContent {
    UIColor *textColor = self.message.isFromCurrentUser ? [UIColor whiteColor] : CLBExtraDarkGrayColor(YES);
    self.filenameLabel.textColor = textColor;
    self.filenameLabel.text = CLBFilenameForURL(self.message.mediaUrl);
    CGFloat fullIconWidth = self.fileIcon.frame.size.width + CLBSOFileMessageCellViewPadding.left + CLBSOFileMessageCellViewPadding.right;
    CGFloat maxAvailableWidth = self.messageMaxWidth - fullIconWidth;
    CGSize filenameLabelSize = [self.filenameLabel sizeThatFits:CGSizeMake(maxAvailableWidth, kCellHeight)];
    self.sizeLabel.textColor = textColor;
    
    CGSize textSize = CGSizeZero;
    CGFloat separatorHeight = 0;
    
    if (self.message.text) {
        [self.vendingMachine setTextForMessage:self.message onTextView:self.messageTextLabel withAccentColor:self.accentColor userMessageTextColor:self.userMessageTextColor];
        textSize = [self.vendingMachine sizeForMessage:self.message constrainedToWidth:self.messageMaxWidth usingTextView:self.messageTextLabel];
        textSize.width += kHorizontalPadding * 2;
        textSize.height += CLBSOFileMessageCellViewPadding.top + CLBSOFileMessageCellViewPadding.bottom;
        self.messageTextLabel.textColor = textColor;
        self.messageTextLabel.hidden = NO;
        separatorHeight = kSeparatorHeight;
        self.separatorView.hidden = NO;
        self.separatorView.backgroundColor = [textColor colorWithAlphaComponent:.3];
    } else {
        self.messageTextLabel.frame = CGRectZero;
        self.messageTextLabel.hidden = YES;
        self.separatorView.frame = CGRectZero;
        self.separatorView.hidden = YES;
    }
    
    long long size = [self.message.mediaSize longLongValue];
    
    NSString *sizeLabelText;
    if (size > 0) {
        NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
        sizeLabelText = [formatter stringFromByteCount:size];
    }
    
    self.sizeLabel.text = sizeLabelText;
    CGSize sizeLabelSize = [self.sizeLabel sizeThatFits:CGSizeMake(maxAvailableWidth, kCellHeight)];
    
    CGFloat fileContainerWidth = MAX(filenameLabelSize.width, sizeLabelSize.width) + fullIconWidth + CLBSOFileMessageCellViewPadding.right;
    CGFloat cellWidth = MAX(fileContainerWidth, textSize.width);
    
    CGRect contentFrame = CGRectMake(0, 0, cellWidth, textSize.height + separatorHeight + kCellHeight);
    
    [self layoutBubble:contentFrame];
    
    if (self.message.text) {
        self.messageTextLabel.frame = CGRectMake(self.bubbleView.frame.origin.x + kHorizontalPadding, CLBSOFileMessageCellViewPadding.top, cellWidth - kHorizontalPadding * 2, textSize.height - CLBSOFileMessageCellViewPadding.top);
        self.separatorView.frame = CGRectMake(self.bubbleView.frame.origin.x + kHorizontalPadding, CGRectGetMaxY(self.messageTextLabel.frame), cellWidth - kHorizontalPadding * 2, separatorHeight);
    }
    
    self.fileContainerView.frame = CGRectMake(self.bubbleView.frame.origin.x, CGRectGetMaxY(self.separatorView.frame), cellWidth, kCellHeight);
    
    self.fileIcon.tintColor = self.message.isFromCurrentUser ? [UIColor whiteColor] : CLBExtraDarkGrayColor(YES);
    [self adjustFileIcon];
    
    CGFloat filenameLabelX = CGRectGetMaxX(self.fileIcon.frame) + CLBSOFileMessageCellViewPadding.right;
    CGFloat filenameLabelY = self.fileContainerView.frame.size.height / 2 - filenameLabelSize.height;
    self.filenameLabel.frame = CGRectMake(filenameLabelX, filenameLabelY, filenameLabelSize.width, filenameLabelSize.height);
    self.sizeLabel.frame = CGRectMake(filenameLabelX, self.fileContainerView.frame.size.height / 2, sizeLabelSize.width, sizeLabelSize.height);
    
    if (!sizeLabelText) {
        self.filenameLabel.center = CGPointMake(self.filenameLabel.center.x, CGRectGetMidY(self.bubbleView.bounds));
    }
    
    [self adjustTapGesture];
    [self adjustProgressOverlay];
}

-(void)adjustProgressOverlay {
    if(!self.message.sent && !self.message.failed) {
        self.progressOverlayMask.hidden = NO;
        self.progressOverlay.frame = self.bubbleView.frame;
        self.progressOverlayMask.frame = self.bubbleView.frame;
        [self watchProgressNotifications];
    } else {
        [self stopWatchingProgressNotifications];
        self.progressOverlay.frame = CGRectZero;
        self.progressOverlayMask.frame = CGRectZero;
        self.progressOverlayMask.hidden = YES;
    }
}

-(void)adjustFileIcon {
    CGRect iconFrame = self.fileIcon.frame;
    CGFloat x = CLBSOFileMessageCellViewPadding.left;
    CGFloat y = self.fileContainerView.frame.size.height / 2 - self.fileIcon.frame.size.height / 2;
    self.fileIcon.frame = CGRectMake(x, y, iconFrame.size.width, iconFrame.size.height);
    self.fileIcon.backgroundColor = [UIColor clearColor];
}

-(void)layoutBubble:(CGRect)contentFrame {
    CGRect balloonFrame = CGRectZero;
    balloonFrame.size.width = contentFrame.size.width;
    balloonFrame.size.height = CGRectGetMaxY(contentFrame);
    balloonFrame.origin.y = 0;
    
    if (!self.message.isFromCurrentUser && self.userImage) {
        balloonFrame.origin.x = kUserImageViewRightMargin + self.userImageViewSize.width;
    }
    
    if (!self.message.isFromCurrentUser && !CGSizeEqualToSize(self.userImageViewSize, CGSizeZero) && self.userImage) {
        if (balloonFrame.size.height < self.userImageViewSize.height) {
            balloonFrame.size.height = self.userImageViewSize.height;
        }
    }
    
    self.bubbleView.frame = balloonFrame;
}

+(CGFloat)heightForMessage:(id<CLBSOMessage>) message withVendingMachine:(CLBTextViewVendingMachine *)vendingMachine maxWidth:(CGFloat)maxWidth {
    CGFloat height = kCellHeight;
    
    if (message.text) {
        height += [vendingMachine sizeForMessage:message constrainedToWidth:maxWidth].height;
        height += CLBSOFileMessageCellViewPadding.top + CLBSOFileMessageCellViewPadding.bottom;
        height += kSeparatorHeight;
    }
    
    return height;
}

-(void)adjustTapGesture {
    [self.fileContainerView removeGestureRecognizer:self.fileTapGesture];
    
    if (self.message.sent) {
        [self.fileContainerView addGestureRecognizer:self.fileTapGesture];
    }
}

-(void)fileMessageTapped {
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageCell:didSelectMediaUrl:)]) {
        [self.delegate messageCell:self didSelectMediaUrl:self.message.mediaUrl];
    }
}

-(void)updateProgress {
    [self updateProgressAnimated:YES];
}

-(void)updateProgressAnimated:(BOOL)animated {
    self.progressOverlay.frame = self.bubbleView.frame;
    self.progressOverlayMask.frame = self.bubbleView.frame;
    CGPoint position = CGPointMake(self.message.progress * self.bubbleView.frame.size.width, 0);
    if(animated){
        CGFloat duration = 3.0;
        CLBEnsureMainThread(^{
            [UIView animateWithDuration:duration animations:^{
                self.progressOverlayMask.position = position;
            }];
        });
    }else{
        self.progressOverlayMask.position = position;
    }
}

-(void)watchProgressNotifications {
    [self stopWatchingProgressNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress) name:CLBFileUploadMessageProgressDidChangeNotification object:self.message];
}

-(void)stopWatchingProgressNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)dealloc {
    [self stopWatchingProgressNotifications];
}

@end
