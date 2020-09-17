//
//  SOMessageCell.h
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

#import <UIKit/UIKit.h>
#import "CLBSOMessage.h"
#import "CLBSOMessagingDelegate.h"
#import "CLBMessageItemView.h"
@class CLBRoundedRectView;
@class CLBMessageAction;

static const CGFloat kBubbleLeftMargin = 9;
static const CGFloat kBubbleRightMargin = 9;
static const CGFloat kBubbleBottomMargin = 2;

static const CGFloat kFontSize = 16;

static const CGFloat kAvatarWidth = 37;
static const CGSize kAvatarSize = { kAvatarWidth, kAvatarWidth };
static const CGFloat kMinimumMessageWidth = 130;

static const int kUserImageViewRightMargin = 5;

@class CLBSOMessageCell;
@protocol CLBSOMessageCellDelegate <CLBSOMessagingDelegate>

@optional
-(void)messageCellDidTapMedia:(CLBSOMessageCell *)cell;
-(void)messageCell:(CLBSOMessageCell *)cell didTapImage:(UIImage *)image onMessageItemView:(CLBMessageItemView *)messageItemView;
-(void)messageCell:(CLBSOMessageCell *)cell didSelectLink:(NSURL*)link;
-(void)messageCell:(CLBSOMessageCell *)cell didSelectMediaUrl:(NSString*)mediaUrl;
-(void)messageCell:(CLBSOMessageCell *)cell didSelectAction:(CLBMessageAction*)action;

@end

@interface CLBSOMessageCell : UITableViewCell

@property (weak, nonatomic) UITableView *tableView;
@property (weak, nonatomic) id<CLBSOMessage> message;
@property (weak, nonatomic) UIImage *userImage;

@property (strong, nonatomic) UIImageView *userImageView;
@property (strong, nonatomic) UILabel *timeLabel; //appears while dragging cell

@property (strong, nonatomic) UIColor* bubbleColor;
@property (strong, nonatomic) CLBRoundedRectView *bubbleView;

@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;

@property UITapGestureRecognizer* tapGesture;

@property CGFloat bubbleTopMargin;

@property (nonatomic) CGFloat messageMaxWidth;

@property (nonatomic) UIEdgeInsets contentInsets;

@property BOOL showName;
@property BOOL showUserImage;
@property BOOL showStatus;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UIView *containerView;
@property UILabel* bottomLabel;

@property (weak, nonatomic) id<CLBSOMessageCellDelegate> delegate;

@property (nonatomic) CGSize mediaImageViewSize;
@property (nonatomic) CGSize userImageViewSize;

@property UIColor* accentColor;
@property UIColor* userMessageTextColor;

- (void)adjustCell;
- (void)layoutContent;
- (void)onImageLoaded:(UIImage*)image;
- (BOOL)shouldOffsetFrameForTimeReveal;

@end
