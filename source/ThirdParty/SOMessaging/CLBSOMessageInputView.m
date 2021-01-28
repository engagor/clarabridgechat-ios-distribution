//
//  SOMessageInputView.m
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

#import "CLBSOMessageInputView.h"
#import <QuartzCore/QuartzCore.h>
#import "CLBUtility.h"
#import "CLBLocalization.h"
#import "CLBSOMessagingViewController.h"
#import "ClarabridgeChat+Private.h"

static const CGFloat kSendButtonRightPadding = 18;
static const CGFloat kTableViewBottomPadding = 8;
static const int kMaxMessageLength = 10000;
static NSString* const kCameraIcon = @"";

@interface CLBSOMessageInputView() <UITextViewDelegate> {
    UITapGestureRecognizer *tapGesture;
}

@property BOOL scrollTextViewToCaret;
@property int maxMessageLength;

@property (weak) CLBSOMessagingViewController* viewController;

@end

@implementation CLBSOMessageInputView

@synthesize displayed = _displayed;

- (instancetype)initWithFrame:(CGRect)frame viewController:(CLBSOMessagingViewController *)viewController delegate:(id<CLBSOMessagingDelegate>)delegate {
    self = [super initWithFrame:frame];
    if (self) {
        _viewController = viewController;
        _displayed = [CLBSOMessagingViewController isInputDisplayed];
        self.delegate = delegate;
        [self setupInitialData];
        [self setupWithColor:_viewController.accentColor];
    }
    return self;
}

- (void)setupInitialData {
    self.textInitialHeight = 45.0f;
    self.textleftMargin = 4.0f;
    self.textTopMargin = 7.5f;
    self.textBottomMargin = 7.5f;
    self.textRightMargin = -15.0f;
    self.maxMessageLength = kMaxMessageLength;
}

- (void)setupWithColor:(UIColor*)color {
    self.backgroundColor = CLBSystemBackgroundColor();

    self.textView = [[CLBSOPlaceholderedTextView alloc] init];
    self.textView.textColor = CLBExtraDarkGrayColor(YES);
    self.textView.delegate = self;
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.tintColor = color;
    
    [self addSubview:self.textView];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sendButton.enabled = NO;
    [self.sendButton addTarget:self action:@selector(sendTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setTitle:[CLBLocalization localizedStringForKey:@"Send"] forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.sendButton setTitleColor:CLBDarkGrayColor(NO) forState:UIControlStateDisabled];
    [self.sendButton setTitleColor:color forState:UIControlStateNormal];
    [self.sendButton sizeToFit];
    self.sendButton.frame = CGRectMake(self.bounds.size.width - self.sendButton.frame.size.width - kSendButtonRightPadding,
                      self.bounds.size.height - self.textInitialHeight - 1,
                      self.sendButton.frame.size.width + kSendButtonRightPadding,
                      self.textInitialHeight);
    self.sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [self addSubview:self.sendButton];
    BOOL shouldDisplayMediaOptions = YES;
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(shouldDisplayMediaButton)]){
        shouldDisplayMediaOptions = [self.delegate shouldDisplayMediaButton];
    }
    
    if(shouldDisplayMediaOptions){
        self.mediaButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.mediaButton addTarget:self action:@selector(mediaTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.mediaButton.contentMode = UIViewContentModeScaleAspectFit;
        self.mediaButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.mediaButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:self.mediaButton];
        self.mediaButton.imageEdgeInsets = UIEdgeInsetsZero;
    }
    
    CGFloat separatorHeight = 0.5;
    
    BOOL isRetina = [UIScreen mainScreen].scale > 1.0;
    
    // BUG FIX : iPhone 4s and iPad non-retina doesn't like 0.5 height
    if(!CLBIsTallScreenDevice() || !isRetina){
        separatorHeight = 1.0;
    }
    
    self.separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, separatorHeight)];
    self.separatorView.backgroundColor = CLBLightGrayColor();
    self.separatorView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.separatorView];
    
    self.textView.placeholderText = [CLBLocalization localizedStringForKey:@"Type a message..."];
    self.textView.placeholderTextColor = CLBLightGrayColor();
    
    if(shouldDisplayMediaOptions){
        [self.mediaButton setImage:[ClarabridgeChat getImageFromResourceBundle:@"mediaButton"] forState:UIControlStateNormal];
        self.mediaButton.frame = CGRectMake(0, 0, 40, self.bounds.size.height);
    }
    
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tapGesture];
}

-(CGFloat)textMaxHeight {
    if(CLBIsLayoutPhoneInLandscape()){
        return 75;
    }else{
        return 125;
    }
}

#pragma mark - Actions
- (void)sendTapped:(id)sender {
    NSString *msg = self.textView.text;
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageInputView:shouldSendMessage:)]) {
        if(![self.delegate messageInputView:self shouldSendMessage:msg]){
            return;
        }
    }

    self.textView.text = @"";
    self.sendButton.enabled = NO;
    [self reframeAnimated:NO];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageInputView:didSendMessage:)]) {
        [self.delegate messageInputView:self didSendMessage:msg];
    }
}

- (void)mediaTapped:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageInputViewDidSelectMediaButton:)]) {
        [self.delegate messageInputViewDidSelectMediaButton:self];
    }
}

#pragma mark - private Methods

-(void)shakeSendButton {
    self.sendButton.transform = CGAffineTransformMakeScale(1.15 , 1.15);
    [UIView animateWithDuration:0.75
                          delay:0.0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.sendButton.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
}

#pragma mark - textview delegate

- (void)textViewDidChange:(UITextView *)textView {
    self.scrollTextViewToCaret = YES;
    [self reframeAnimated:NO];
    
    BOOL hasText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0;
    
    BOOL wasSendButtonEnabled = self.sendButton.enabled;
    self.sendButton.enabled = hasText;
    if (self.sendButton.enabled && !wasSendButtonEnabled) {
        [self shakeSendButton];
    }

    if (hasText) {
        if (self.inputDelegate && [self.inputDelegate respondsToSelector:@selector(inputViewDidBeginTyping:)]) {
            [self.inputDelegate inputViewDidBeginTyping:self];
        }
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
    [self scrollToBottom];
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    if (self.inputDelegate && [self.inputDelegate respondsToSelector:@selector(inputViewDidFinishTyping:)]) {
        [self.inputDelegate inputViewDidFinishTyping:self];
    }
}

#pragma mark - Notifications handlers

-(void)reframe:(CGFloat)keyboardHeight {
    CGFloat width = self.superview.bounds.size.width;
    
    CGFloat textViewWidth = width - self.mediaButton.frame.size.width - self.textleftMargin - self.sendButton.frame.size.width - self.textRightMargin - kSendButtonRightPadding;
    CGFloat textViewMaxHeight = self.textMaxHeight - self.textTopMargin - self.textBottomMargin;
    CGFloat textViewMinHeight = self.textInitialHeight - self.textTopMargin - self.textBottomMargin;
    
    CGSize textViewSize = [self.textView.text boundingRectWithSize:CGSizeMake(textViewWidth, textViewMaxHeight)
                                                          options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                       attributes:@{ NSFontAttributeName:self.textView.font }
                                                          context:nil].size;

    textViewSize = CGSizeMake(ceilf(textViewSize.width), ceilf(textViewSize.height));
    
    if(textViewSize.height < textViewMinHeight){
        textViewSize.height = textViewMinHeight;
    }else if (textViewSize.height > textViewMaxHeight){
        textViewSize.height = textViewMaxHeight;
    }
    
    CGRect textViewFrame = CGRectMake(CGRectGetMaxX(self.mediaButton.frame) + self.textleftMargin,
                                      self.textTopMargin,
                                      textViewWidth,
                                      textViewSize.height);
    
    CGFloat height = textViewFrame.size.height + self.textTopMargin + self.textBottomMargin;
    
    BOOL isTabBarTranslucent = self.viewController.tabBarController.tabBar.translucent;
    CGFloat offsetForTabBar;
    
    if(self.viewController.hidesBottomBarWhenPushed){
        offsetForTabBar = 0;
    } else if(self.viewController.tabBarController.tabBar.hidden) {
        offsetForTabBar = 0;
    }else if(isTabBarTranslucent && keyboardHeight == 0){
        offsetForTabBar = CLBIsIOS11OrLater() ? 0 : [self tabBarHeight];
    }else if(!isTabBarTranslucent && keyboardHeight > 0){
        offsetForTabBar = -([[UIScreen mainScreen] bounds].size.height - CGRectGetMaxY(self.superview.frame));
    }else{
        offsetForTabBar = 0;
    }
    
    CGFloat superviewHeight = self.superview.bounds.size.height;
    CGFloat superviewWidth;
    CGFloat frameX;
    
    if (CLBIsIOS11OrLater()) {
        
        CGRect superviewSafeArea = CLBSafeBoundsForView(self.superview);
        
        if (keyboardHeight == 0) {
            superviewHeight = CGRectGetMaxY(superviewSafeArea);
        }
        
        superviewWidth = superviewSafeArea.size.width;
        frameX = superviewSafeArea.origin.x;
    } else {
        superviewWidth = self.superview.bounds.size.width;
        frameX = 0;
    }
    
    CGRect newFrame;
    
    if (self.displayed) {
        newFrame = CGRectMake(frameX,
                     superviewHeight - height - keyboardHeight - offsetForTabBar,
                     superviewWidth,
                     height);
        self.hidden = NO;
    } else {
        newFrame = CGRectZero;
        self.hidden = YES;
    }
    
    if(!CGRectEqualToRect(newFrame, self.frame)){
        self.frame = newFrame;
    }
    
    // Make the top border stretch all the way to the sides on iPhone X landscape
    self.separatorView.frame = CGRectMake(-frameX, 0, self.viewController.view.bounds.size.width, self.separatorView.frame.size.height);

    if(!CGRectEqualToRect(textViewFrame, self.textView.frame)){
        self.textView.frame = textViewFrame;
        
        // BUG FIX : Pressing return caused the caret and text to be positioned oddly
        if(self.scrollTextViewToCaret){
            self.scrollTextViewToCaret = NO;
            [self.textView scrollRangeToVisible:self.textView.selectedRange];
        }
        
        // Mad props : https://gist.github.com/troyharris/6257332
        [self.textView.layoutManager ensureLayoutForTextContainer:self.textView.textContainer];
    }
    
    UIEdgeInsets contentInsets;
    if (CLBIsIOS11OrLater()) {        
        CGFloat bottomInset = keyboardHeight + self.frame.size.height + kTableViewBottomPadding + offsetForTabBar;
        if (keyboardHeight > 0) {
            bottomInset -= CLBSafeAreaInsetsForView(self.viewController.view).bottom;
        }
        contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, 0.0, bottomInset, 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, 0.0, keyboardHeight + self.frame.size.height + kTableViewBottomPadding + offsetForTabBar, 0.0);
    }
    UIEdgeInsets scrollInsets = UIEdgeInsetsMake(contentInsets.top, contentInsets.left, contentInsets.bottom - kTableViewBottomPadding, contentInsets.right);
    
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = scrollInsets;
}

-(void)scrollToBottom {
    NSInteger section = [self.tableView numberOfSections] - 1;
    if (section >= 0) {
        NSInteger row = [self.tableView numberOfRowsInSection:section] - 1;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        if (row >= 0) {
            [UIView animateWithDuration:self.keyboardAnimationDuration animations:^{
                [UIView setAnimationCurve:self.keyboardAnimationCurve];
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            }];
        }
    }
}

-(void)setDisplayed:(BOOL)isDisplayed {
    _displayed = isDisplayed;
    
    if (!_displayed) {
        [self resignFirstResponder];
    }
    
    [self reframeAnimated:NO];
}

-(BOOL)displayed {
    return _displayed;
}

#pragma mark - Gestures
- (void)handleTap:(UITapGestureRecognizer *)tap {
    if (![self.textView isFirstResponder]) {
        [self.textView becomeFirstResponder];
    }
}

-(CGFloat)tabBarHeight {
    UITabBarController* tb = self.viewController.tabBarController;
    if(tb){
        return tb.tabBar.frame.size.height;
    }else{
        return 0;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return textView.text.length + (text.length - range.length) <= self.maxMessageLength;
}

@end
