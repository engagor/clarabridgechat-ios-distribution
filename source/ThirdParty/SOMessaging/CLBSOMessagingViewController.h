//
//  SOMessagingViewController.h
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
#import "CLBSOMessagingDataSource.h"
#import "CLBSOMessagingDelegate.h"
#import "CLBSOMessageInputView.h"
#import "CLBSOMessage.h"
#import "CLBSOMessageCell.h"

@class CLBSOImageBrowserView;

typedef NS_ENUM(NSInteger, CLBTableViewLoadStatus) {
    CLBTableViewLoadStatusDelayed = 0,
    CLBTableViewLoadStatusLoading = 1,
    CLBTableViewLoadStatusFetchingPrevious = 2,
    CLBTableViewLoadStatusLoaded = 3
};

@interface CLBSOMessagingViewController : UIViewController <CLBSOMessagingDataSource, CLBSOMessagingDelegate, UITableViewDataSource, CLBSOMessageCellDelegate, CLBSOMessageInputViewDelegate>

-(instancetype)initWithAccentColor:(UIColor*)accentColor userMessageTextColor:(UIColor*)userMessageTextColor carouselTextColor:(UIColor*)carouselTextColor;

+(void)setInputDisplayed:(BOOL)displayed;
+(BOOL)isInputDisplayed;

#pragma mark - Properties
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) CLBSOMessageInputView *chatInputView;

#pragma mark - Methods

/**
 * Reloading datasource
 */
-(void)refreshMessages;
-(void)refreshMessagesAndKeepOffset:(BOOL)keepOffset;
-(void)refreshMessagesAndKeepOffset:(BOOL)keepOffset animateScrollToBottom:(BOOL)animateScroll;

- (UIImage *)tintImage:(UIImage *)image withColor:(UIColor *)color;

-(BOOL)shouldIndexShowName:(NSInteger)index;

@property UIColor* accentColor;
@property UIColor* userMessageTextColor;
@property UIColor* carouselTextColor;
@property (strong, nonatomic) CLBSOImageBrowserView *imageBrowser;
@property CLBTableViewLoadStatus loadStatus;
@property CGFloat errorBannerHeight;
@property (copy) NSString *startingText;

@end
