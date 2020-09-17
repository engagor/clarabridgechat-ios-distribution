//
//  CLBWebviewViewController.m
//  ClarabridgeChat
//
//  Copyright © 2017 Smooch Technologies. All rights reserved.
//

#import "CLBWebviewViewController.h"
#import "CLBMessageAction.h"
#import "CLBUtility.h"
#import "CLBLocalization.h"
#import "ClarabridgeChat+Private.h"
#import <WebKit/WebKit.h>

static CGFloat const kTopPadding = 20;
static CGFloat const kProgressViewHeight = 2;
static CGFloat const kSeparatorViewHeight = 1;
static CGFloat const kTransitionAnimationDuration = 0.2;
static NSString * const kScriptMessageHandlerName = @"iOSWebviewInterface";
static NSString * const kScriptMessageTypeClose = @"CLOSE_WEBVIEW";
static NSString * const kScriptMessageTypeSetTitle = @"SET_TITLE";

@interface CLBWebviewViewController () <WKNavigationDelegate, WKScriptMessageHandler>

@property(nonatomic, strong) CLBMessageAction *action;
@property(nonatomic, strong) UIView *containerView;
@property(nonatomic, strong) UIView *separatorView;
@property(nonatomic, strong) UINavigationBar *navBar;
@property(nonatomic, strong) UIBarButtonItem *backButton;
@property(nonatomic, strong) WKWebView *webview;
@property(nonatomic, strong) UIProgressView *progressView;
@property(nonatomic, strong) UILabel *errorMessageView;
@property BOOL shouldAnimateInTransition;
@property CGFloat keyboardHeight;

@end

@implementation CLBWebviewViewController

-(instancetype)initWithAction:(CLBMessageAction *)action {
    self = [super init];
    
    if (self) {
        _action = action;
        _shouldAnimateInTransition = YES;
        _keyboardHeight = 0;
    }
    
    return self;
}

-(void)dealloc {
    [self.webview removeObserver:self forKeyPath:@"estimatedProgress"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progressView.progress = self.webview.estimatedProgress;
        self.progressView.hidden = self.progressView.progress == 0 || self.progressView.progress == 1;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHidden:) name:UIKeyboardWillHideNotification object:nil];
    [self setUpView];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reframeView];
    [self loadWebContent];
}

-(void)setUpView {
    self.view.backgroundColor = CLBWebviewBackgroundColor();
    [self setUpContainer];
    [self setUpNavBar];
    [self setUpWebview];
    [self setUpProgressView];
    [self setUpErrorMessageView];
}

-(void)setUpContainer {
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.containerView];
}

-(void)setUpNavBar {
    self.navBar = [[UINavigationBar alloc] init];
    self.navBar.backgroundColor = [UIColor whiteColor];
    self.navBar.translucent = NO;
    UINavigationItem *navigationItem = [[UINavigationItem alloc] init];
    navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[CLBLocalization localizedStringForKey:@"Done"] style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    self.backButton = [[UIBarButtonItem alloc] initWithImage:[ClarabridgeChat getImageFromResourceBundle:@"backArrow"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    
    [self.navBar pushNavigationItem:navigationItem animated:NO];
    [self.containerView addSubview:self.navBar];
}

-(void)setUpWebview {
    self.webview = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[self configuration]];
    self.webview.navigationDelegate = self;
    self.webview.allowsBackForwardNavigationGestures = YES;
    [self.webview addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self.containerView addSubview:self.webview];
}

-(void)setUpProgressView {
    self.separatorView = [[UIView alloc] initWithFrame:CGRectZero];
    self.separatorView.backgroundColor = CLBLightGrayColor();
    self.separatorView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self.containerView addSubview:self.separatorView];
    
    self.progressView = [[UIProgressView alloc] init];
    self.progressView.progressViewStyle = UIProgressViewStyleBar;
    self.progressView.progress = 0;
    [self.containerView addSubview:self.progressView];
}

-(void)setUpErrorMessageView {
    self.errorMessageView = [[UILabel alloc] initWithFrame:CGRectZero];
    self.errorMessageView.text = [CLBLocalization localizedStringForKey:@"Failed to open the page"];
    self.errorMessageView.hidden = YES;
    [self.containerView addSubview:self.errorMessageView];
}

-(void)viewDidLayoutSubviews {
    [self reframeView];
}

-(void)reframeView {
    [self reframeContainer];
    [self reframeNavBar];
    [self reframeWebView];
    [self reframeErrorMessageView];
    if (self.shouldAnimateInTransition) {
        [self animateContainerInTransition];
    }
}

-(void)reframeContainer {
    NSString *size = self.action.size;
    CGRect safeBounds = CLBSafeBoundsForView(self.view);
    UIEdgeInsets safeArea = CLBSafeAreaInsetsForView(self.view);
    
    CGFloat x = safeBounds.origin.x;
    CGFloat y;
    CGFloat height;
    CGFloat width = safeBounds.size.width;
    
    if (CLBIsIpad()) {
        width = width * .5;
    }
    
    if ([size isEqualToString:CLBMessageActionWebviewSizeCompact]) {
        height = self.view.frame.size.height * (CLBIsIpad() ? .4 : .5);
    } else if ([size isEqualToString:CLBMessageActionWebviewSizeTall]) {
        height = self.view.frame.size.height * (CLBIsIpad() ? .5 : .7);
    } else {
        // Size "full" is default
        height = self.view.frame.size.height * (CLBIsIpad() ? .7 : 1);
    }
    
    if (CLBIsLayoutPhoneInLandscape() || !CLBIsIOS11OrLater()) {
        height -= kTopPadding;
    }
    
    if (CLBIsIpad()) {
        x = self.view.frame.size.width / 2 - (width / 2);
        y = self.view.frame.size.height / 2 - (height / 2);
    } else {
        y = self.view.frame.size.height + safeArea.top - height;
    }
    
    if (self.keyboardHeight > 0) {
        CGFloat maxY = (CLBIsLayoutPhoneInLandscape() || !CLBIsIOS11OrLater()) ? kTopPadding : safeArea.top;
        if (CLBIsIpad()) {
            CGFloat keyboardY = self.view.frame.size.height - self.keyboardHeight;
            CGFloat containerY = y + height;
            
            if (containerY > keyboardY) {
                y = MAX(maxY, keyboardY - height);
            }
        } else {
            y = MAX(maxY, y - self.keyboardHeight);
        }
        
        CGFloat availableHeight = self.view.frame.size.height - self.keyboardHeight - (CLBIsIpad() ? y : 0);
        height = MIN(height, availableHeight);
    }
    
    CGRect frame = CGRectMake(x, y, width, height);
    
    if (!CGRectEqualToRect(frame, self.containerView.frame)) {
        self.containerView.frame = frame;
        [self roundContainerViewCorners];
    }
}

-(void)roundContainerViewCorners {
    CGRect layerFrame = CGRectMake(0, 0, self.containerView.frame.size.width, self.containerView.frame.size.height);
    UIRectCorner roundedCorners = CLBIsIpad() ? UIRectCornerAllCorners : (UIRectCornerTopRight|UIRectCornerTopLeft);
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:layerFrame byRoundingCorners:roundedCorners cornerRadii:CGSizeMake(12, 12)];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = layerFrame;
    layer.path = shadowPath.CGPath;
    self.containerView.layer.mask = layer;
}

-(void)reframeNavBar {
    CGRect navBarFrame = CGRectMake(0, 0, self.containerView.frame.size.width, CLBNavBarHeight() - CLBStatusBarHeight());
    
    if (!CGRectEqualToRect(navBarFrame, self.navBar.frame)) {
        self.navBar.frame = navBarFrame;
        self.progressView.frame = CGRectMake(navBarFrame.origin.x, navBarFrame.size.height - kProgressViewHeight, navBarFrame.size.width, kProgressViewHeight);
        self.separatorView.frame = CGRectMake(navBarFrame.origin.x, navBarFrame.size.height - kSeparatorViewHeight, navBarFrame.size.width, kSeparatorViewHeight);
    }
}

-(void)reframeWebView {
    CGFloat x = 0;
    CGFloat y = CGRectGetMaxY(self.navBar.frame);
    CGFloat width = self.containerView.frame.size.width;
    CGFloat height = self.containerView.bounds.size.height - y;
    
    if (CLBIsLayoutPhoneInLandscape()) {
        height += CLBSafeAreaInsetsForView(self.view).bottom;
    } else if (!CLBIsIpad()) {
        height -= CLBSafeAreaInsetsForView(self.view).top;
    }
    
    CGRect webviewFrame = CGRectMake(x, y, width, height);
    
    if (!CGRectEqualToRect(webviewFrame, self.webview.frame)) {
        self.webview.frame = webviewFrame;
    }
}

-(void)reframeErrorMessageView {
    [self.errorMessageView sizeToFit];
    self.errorMessageView.center = self.webview.center;
}

-(void)animateContainerInTransition {
    CGRect finalFrame = self.containerView.frame;
    self.containerView.frame = CGRectMake(finalFrame.origin.x, self.view.frame.size.height, finalFrame.size.width, finalFrame.size.height);
    
    [UIView animateWithDuration:kTransitionAnimationDuration animations:^{
        self.containerView.frame = finalFrame;
    } completion:^(BOOL finished) {
        self.shouldAnimateInTransition = NO;
    }];
}

-(WKWebViewConfiguration *)configuration {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = [[WKUserContentController alloc] init];
    [configuration.userContentController addScriptMessageHandler:self name:kScriptMessageHandlerName];
    return configuration;
}

-(void)loadWebContent {
    NSURLRequest *request = [NSURLRequest requestWithURL:self.action.uri];
    [self.webview loadRequest:request];
}

-(void)webviewDidFailToLoadContent {
    self.progressView.progress = 0;
    self.errorMessageView.hidden = NO;
}

-(void)goBack {
    if (self.webview.canGoBack) {
        [self.webview goBack];
    }
}

#pragma mark - Webview extensions

-(void)close {
    [UIView animateWithDuration:kTransitionAnimationDuration animations:^{
        self.containerView.frame = CGRectMake(self.containerView.frame.origin.x, self.view.frame.size.height, self.containerView.frame.size.width, self.containerView.frame.size.height);
    } completion:^(BOOL finished) {
        if (finished) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

-(void)setTitle:(NSString *)title {
    self.navBar.topItem.title = title;
}

#pragma mark - WKNavigationDelegate

-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self webviewDidFailToLoadContent];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.navBar.topItem.title = webView.title;
    self.navBar.topItem.leftBarButtonItem = webView.canGoBack ? self.backButton : nil;
    self.progressView.progress = 0;
    self.errorMessageView.hidden = YES;
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *scheme = navigationAction.request.URL.scheme;
    if ([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"]) {
        // target "_blank"
        if (!navigationAction.targetFrame) {
            [webView loadRequest:navigationAction.request];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    } else if (navigationAction.request.URL) {
        // other schemes (mailto, sms, tel)
        CLBOpenExternalURL(navigationAction.request.URL);
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKScriptMessageHandler

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:kScriptMessageHandlerName]) {
        if ([message.body isKindOfClass:[NSDictionary class]]) {
            if ([message.body[@"type"] isEqualToString:kScriptMessageTypeClose]) {
                [self close];
            } else if ([message.body[@"type"] isEqualToString:kScriptMessageTypeSetTitle]) {
                [self setTitle:message.body[@"title"]];
            }
        }
    }
}

#pragma mark - Keyboard

-(void)keyboardShown:(NSNotification *)notification {
    self.keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    [self reframeView];
}

-(void)keyboardHidden:(NSNotification *)notification {
    self.keyboardHeight = 0;
    [self reframeView];
}

@end
