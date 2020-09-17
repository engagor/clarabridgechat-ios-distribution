//
//  SOImageBrowserView.m
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

#import "CLBSOImageBrowserView.h"
#import "CLBUtility.h"

static const CGFloat kImagePadding = 20;

@interface CLBSOImageBrowserView()

@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UIImageView *imageView;
@property BOOL isExpanded;

@end

@implementation CLBSOImageBrowserView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = [UIColor blackColor];
        _backgroundView.alpha = 0;
        [_backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)]];
        
        UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
        swipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
        [_backgroundView addGestureRecognizer:swipeGesture];
        
        swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
        swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
        [_backgroundView addGestureRecognizer:swipeGesture];
        
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled = NO;
        
        [self addSubview:_backgroundView];
        [self addSubview:_imageView];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    self.backgroundView.frame = self.bounds;
    [self reframeImageView];
}

-(void)reframeImageView {
    if(self.isExpanded){
        self.imageView.frame = CGRectInset(self.superview.bounds, kImagePadding, kImagePadding);
    }else{
        self.imageView.frame = self.startFrame;
    }
}

- (void)showInView:(UIView*)view {
    self.frame = view.bounds;
    [view addSubview:self];
    
    self.imageView.image = self.image;
    [self reframeImageView];
    
    self.isExpanded = YES;
    [UIView animateWithDuration:0.3f animations:^{
        self.backgroundView.alpha = 0.8;
        [self reframeImageView];
    }];
}

- (void)hide {
    self.isExpanded = NO;
    [UIView animateWithDuration:0.3 animations:^{
        [self reframeImageView];
        self.imageView.alpha = 0;
        self.backgroundView.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
