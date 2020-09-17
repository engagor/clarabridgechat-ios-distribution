//
//  SOMessageCell.m
//  SOMessaging
//
// Created by : arturdev
// Copyright (c) 2014 SocialObjects Software. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

#import "CLBSOMessageCell.h"
#import "CLBUtility.h"
#import "CLBSOMessagingDelegate.h"
#import "CLBLocalization.h"
#import "CLBRoundedRectView.h"

@interface CLBSOMessageCell() < UIGestureRecognizerDelegate> {
    BOOL isHorizontalPan;
}

@end

@implementation CLBSOMessageCell

static const CGFloat maxContentOffsetX = 60;

static const CGFloat kNameLabelLeftMargin = 8;
static const CGFloat kNameLabelBottomMargin = 3;
static const CGFloat kBottomLabelFontSize = 11;

static CGFloat initialTimeLabelPosX;
static BOOL cellIsDragging;
static CGFloat contentOffsetX = 0;

static NSDateFormatter* dateFormatter;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        self.panGesture.delegate = self;
        [self addGestureRecognizer:self.panGesture];
        
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retryTapped)];
        
        [self initContainerView];
        [self initUserImageView];
        [self initBalloon];
        [self initTimeLabel];
        [self initNameLabel];
        [self initBottomLabel];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationWillChange) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
        
        self.opaque = YES;
        self.layer.opaque = YES;
        self.contentView.opaque = YES;
        self.contentView.layer.opaque = YES;
        self.contentView.backgroundColor = CLBSystemBackgroundColor();
        self.backgroundColor = CLBSystemBackgroundColor();
    }
    
    return self;
}

-(void)initContainerView {
    self.containerView = [[UIView alloc] initWithFrame:self.contentView.bounds];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    [self.contentView addSubview:self.containerView];
}

-(void)initUserImageView {
    self.userImageView = [[UIImageView alloc] initWithFrame:(CGRect){CGPointZero, kAvatarSize}];
    self.userImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.userImageView.clipsToBounds = YES;
    self.userImageView.backgroundColor = [UIColor clearColor];
    self.userImageView.hidden = YES;
    self.userImageView.layer.cornerRadius = kAvatarWidth / 2;
    
    [self.containerView addSubview:self.userImageView];
}

-(CGSize)userImageViewSize {
    if(self.message.isFromCurrentUser){
        return CGSizeZero;
    }else{
        return kAvatarSize;
    }
}

-(void)initBalloon {
    self.bubbleView = [[CLBRoundedRectView alloc] init];
    
    [self.containerView addSubview:self.bubbleView];
}

- (void)initTimeLabel {
    if(!dateFormatter){
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[CLBLocalization localizedStringForKey:@"hh:mm a"]];
    }
    
    self.timeLabel = [[UILabel alloc] init];
    
    self.contentView.clipsToBounds = NO;
    self.clipsToBounds = NO;
    
    self.timeLabel.font = [UIFont systemFontOfSize:10];
    self.timeLabel.textColor = CLBMediumGrayColor();
    self.timeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    [self.contentView addSubview:self.timeLabel];
}

- (void)initNameLabel {
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:12];
    self.nameLabel.textColor = CLBMediumGrayColor();
    self.nameLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    [self.contentView addSubview:self.nameLabel];
}

-(void)initBottomLabel {
    self.bottomLabel = [[UILabel alloc] init];
    self.bottomLabel.font = [UIFont systemFontOfSize:kBottomLabelFontSize];
    self.bottomLabel.numberOfLines = 2;
    self.bottomLabel.textColor = CLBMediumGrayColor();
    self.bottomLabel.text = [CLBLocalization localizedStringForKey:@"Sending..."];
    self.bottomLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.bottomLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGSize newSize = [self.bottomLabel.text boundingRectWithSize:self.contentView.frame.size
                                           options:NSStringDrawingTruncatesLastVisibleLine
                                        attributes:@{NSFontAttributeName:self.bottomLabel.font}
                                           context:nil].size;
    
    self.bottomLabel.frame = CGRectMake(CGRectGetMaxX(self.containerView.frame) - newSize.width - 5,
                                        CGRectGetMaxY(self.containerView.frame) + 3,
                                        newSize.width + 10,
                                        newSize.height);
    
    [self.contentView addSubview:self.bottomLabel];
}
- (void)onImageLoaded:(UIImage *)image {
    CLBEnsureMainThread(^{
        self.userImage = image;
        self.userImageView.image = self.userImage;
    });
}

-(void)layoutSubviews {
    [UIView setAnimationsEnabled:NO];
    [self adjustCell];
    [UIView setAnimationsEnabled:YES];
}

- (void)adjustCell {
    [self layoutContent];
    [self adjustContentViewAndImageView];
    [self adjustTimeLabel];
    [self adjustNameLabel];
    [self adjustBottomLabel];
    [self adjustGestureRecognizer];
    
    self.bubbleView.backgroundColor = self.bubbleColor;
    self.containerView.autoresizingMask = self.message.isFromCurrentUser ? UIViewAutoresizingFlexibleLeftMargin : UIViewAutoresizingFlexibleRightMargin;
    initialTimeLabelPosX = self.timeLabel.frame.origin.x;
}

-(void)adjustContentViewAndImageView {
    BOOL isFromCurrentUser = self.message.isFromCurrentUser;
    CGRect balloonFrame = self.bubbleView.frame;
    CGSize userImageViewSize = self.userImageViewSize;
    
    CGRect userRect = CGRectZero;
    if(isFromCurrentUser){
        if(!self.userImageView.hidden){
            self.userImageView.hidden = YES;
        }
    }else{
        self.userImageView.hidden = !self.showUserImage;
        
        userRect.size = userImageViewSize;
        userRect.origin.y = balloonFrame.origin.y + balloonFrame.size.height - userRect.size.height;
        userRect.origin.x = balloonFrame.origin.x - kUserImageViewRightMargin - userRect.size.width;
        
        self.userImageView.frame = userRect;
        self.userImageView.image = self.userImage;
    }
    
    CGRect frm = CGRectMake(isFromCurrentUser ? self.contentView.frame.size.width - balloonFrame.size.width - kBubbleRightMargin : kBubbleLeftMargin,
                            self.bubbleTopMargin,
                            balloonFrame.size.width,
                            balloonFrame.size.height);
    
    if (!isFromCurrentUser) {
        // Add space for avatar
        CGFloat offset = kUserImageViewRightMargin + userRect.size.width;
        frm.size.width += offset;
    }
    
    if (frm.size.height < userImageViewSize.height) {
        CGFloat delta = userImageViewSize.height - frm.size.height;
        
        frm.size.height = userImageViewSize.height;
        frm.origin.y += delta;
    }
    
    self.containerView.frame = frm;
}

-(void)adjustTimeLabel {
    // Adjusing time label
    self.timeLabel.text = [dateFormatter stringFromDate:self.message.date];
    
    [self.timeLabel sizeToFit];
    CGRect timeLabel = self.timeLabel.frame;
    timeLabel.origin.x = self.contentView.frame.size.width + 5;
    self.timeLabel.frame = timeLabel;
    self.timeLabel.center = CGPointMake(self.timeLabel.center.x, self.containerView.center.y);
}

-(void)adjustNameLabel {
    if(!self.showName){
        self.nameLabel.hidden = YES;
        return;
    }
    self.nameLabel.hidden = NO;
    self.nameLabel.text = self.message.name;
    self.nameLabel.frame = self.containerView.frame;
    [self.nameLabel sizeToFit];
    
    CGRect avatarFrame = [self convertRect:self.userImageView.frame fromView:self.containerView];
    
    CGRect frame = self.nameLabel.frame;
    frame.size.width = self.messageMaxWidth;
    frame.origin.y = frame.origin.y - frame.size.height - kNameLabelBottomMargin;
    frame.origin.x = CGRectGetMaxX(avatarFrame) + kNameLabelLeftMargin;
    self.nameLabel.frame = frame;
    
    self.nameLabel.autoresizingMask = self.message.isFromCurrentUser ? UIViewAutoresizingFlexibleLeftMargin : UIViewAutoresizingFlexibleRightMargin;
}

-(void)adjustBottomLabel {
    BOOL isFailedOrPendingMessage = self.message.isFromCurrentUser && (self.message.failed || !self.message.sent);
    if (self.showStatus || isFailedOrPendingMessage){
        self.bottomLabel.text = nil;
        self.bottomLabel.attributedText = nil;
        if (self.message.failed) {
            self.bottomLabel.text = [CLBLocalization localizedStringForKey:@"Message not delivered. Tap to retry."];
        } else if (!self.message.sent) {
            self.bottomLabel.text = [CLBLocalization localizedStringForKey:@"Sending..."];
        } else {
            self.bottomLabel.attributedText = [self statusLabelAttributedTextWithStatus:self.message.isFromCurrentUser];
        }
        
        CGSize newSize = [self.bottomLabel sizeThatFits:self.contentView.frame.size];
        
        float x = self.message.isFromCurrentUser ? CGRectGetMaxX(self.containerView.frame) - newSize.width - 5 : self.containerView.frame.origin.x + kAvatarWidth + kNameLabelLeftMargin;
        
        self.bottomLabel.frame = CGRectMake(x,
                                            CGRectGetMaxY(self.containerView.frame) + 3,
                                            newSize.width,
                                            newSize.height);
        self.bottomLabel.hidden = NO;
        if(self.message.image || self.message.sent){
            self.containerView.alpha = 1.0;
        }else{
            self.containerView.alpha = 0.5;
        }
    }else {
        self.bottomLabel.hidden = YES;
        self.containerView.alpha = 1.0;
    }
    self.bottomLabel.autoresizingMask = self.message.isFromCurrentUser ? UIViewAutoresizingFlexibleLeftMargin : UIViewAutoresizingFlexibleRightMargin;
}

-(void)adjustGestureRecognizer {
    [self.contentView removeGestureRecognizer:self.tapGesture];
    if(self.message.isFromCurrentUser && self.message.failed){
        [self.contentView addGestureRecognizer:self.tapGesture];
    }
}

-(void)layoutContent {
    
}

-(NSAttributedString *)statusLabelAttributedTextWithStatus:(BOOL)showStatus {
    if (!self.message.date) {
        return nil;
    }
    
    NSString *timestampText = [self relativeTimestampTextForDate:self.message.date];
    
    if (!timestampText) {
        return nil;
    }
    
    if (showStatus) {
        if (self.message.isRead) {
            NSAttributedString *boldString = [[NSAttributedString alloc] initWithString:[CLBLocalization localizedStringForKey:@"Seen"] attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:kBottomLabelFontSize]}];
            NSAttributedString *regularString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", [[self relativeTimestampTextForDate:self.message.lastRead] lowercaseString]] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:kBottomLabelFontSize]}];
            NSMutableAttributedString *fullString = [NSMutableAttributedString new];
            [fullString appendAttributedString:boldString];
            [fullString appendAttributedString:regularString];
            return fullString;
        }
        
        NSAttributedString *regularString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@. ", [self relativeTimestampTextForDate:self.message.date]] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:kBottomLabelFontSize]}];
        NSAttributedString *boldString = [[NSAttributedString alloc] initWithString:[CLBLocalization localizedStringForKey:@"Delivered"] attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:kBottomLabelFontSize]}];
        NSMutableAttributedString *fullString = [NSMutableAttributedString new];
        [fullString appendAttributedString:regularString];
        [fullString appendAttributedString:boldString];
        return fullString;
    }
    
    return [[NSAttributedString alloc] initWithString:timestampText];
}

-(NSString *)relativeTimestampTextForDate:(NSDate *)date {
    NSTimeInterval timeDifference = [[NSDate date] timeIntervalSinceDate:date];
    
    int minute = 60;
    int hour = 60 * minute;
    int day = 24 * hour;
    int week = 7 * day;
    
    if (timeDifference < minute) {
        return [CLBLocalization localizedStringForKey:@"Just now"];
    } else if (timeDifference < hour) {
        return [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"%.0fm ago"], round(timeDifference / minute)];
    } else if (timeDifference < day) {
        return [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"%.0fh ago"], round(timeDifference / hour)];
    } else if (timeDifference < week) {
        return [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"%.0fd ago"], round(timeDifference / day)];
    }
    
    return nil;
}

#pragma mark - GestureRecognizer delegates
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    CGPoint velocity = [self.panGesture velocityInView:self.panGesture.view];
    if (self.panGesture.state == UIGestureRecognizerStateBegan) {
        isHorizontalPan = fabs(velocity.x) > fabs(velocity.y);
    }
    
    return !isHorizontalPan;
}

#pragma mark - 
-(void)retryTapped {    
    if([self.delegate respondsToSelector:@selector(retryMessage:forCell:)]){
        [self.delegate retryMessage:self.message forCell:self];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint velocity = [pan velocityInView:pan.view];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        isHorizontalPan = fabs(velocity.x) > fabs(velocity.y);
        
        if (!cellIsDragging) {
            initialTimeLabelPosX = self.timeLabel.frame.origin.x;
        }
    }
    
    if (isHorizontalPan) {
        NSArray *visibleCells = [self.tableView visibleCells];
        
        if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled || pan.state == UIGestureRecognizerStateFailed) {
            cellIsDragging = NO;
            [UIView animateWithDuration:0.25 animations:^{
                [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
                for (CLBSOMessageCell *cell in visibleCells) {
                    
                    contentOffsetX = 0;
                    CGRect frame = cell.contentView.frame;
                    frame.origin.x = contentOffsetX;
                    cell.contentView.frame = frame;
                    
                    if (!cell.message.isFromCurrentUser) {
                        CGRect timeframe = cell.timeLabel.frame;
                        timeframe.origin.x = initialTimeLabelPosX;
                        cell.timeLabel.frame = timeframe;
                    }
                }
            }];
        } else {
            cellIsDragging = YES;
            
            CGPoint translation = [pan translationInView:pan.view];
            CGFloat delta = translation.x * (1 - fabs(contentOffsetX / maxContentOffsetX));
            contentOffsetX += delta;
            if (contentOffsetX > 0) {
                contentOffsetX = 0;
            }
            if (fabs(contentOffsetX) > fabs(maxContentOffsetX)) {
                contentOffsetX = -fabs(maxContentOffsetX);
            }
            for (CLBSOMessageCell *cell in visibleCells) {
                if (cell.message.isFromCurrentUser || [cell shouldOffsetFrameForTimeReveal]) {
                    CGRect frame = cell.contentView.frame;
                    frame.origin.x = contentOffsetX;
                    cell.contentView.frame = frame;
                } else {
                    CGRect frame = cell.timeLabel.frame;
                    frame.origin.x = initialTimeLabelPosX - fabs(contentOffsetX);
                    cell.timeLabel.frame = frame;
                }
            }
        }
    }
    
    [pan setTranslation:CGPointZero inView:pan.view];
}

-(BOOL)shouldOffsetFrameForTimeReveal {
    return NO;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    CGRect frame = self.contentView.frame;
    frame.origin.x = contentOffsetX;
    self.contentView.frame = frame;
}

- (void)orientationWillChange {
    self.panGesture.enabled = NO;
    self.panGesture.enabled = YES;
}

#pragma mark - Getters and Setters

+ (CGFloat)maxContentOffsetX {
    return maxContentOffsetX;
}

#pragma mark -
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
