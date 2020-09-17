//
//  CLBConversationViewController.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBConversationViewController.h"
#import "CLBUtility.h"
#import "CLBLocalization.h"
#import "CLBConversation+Private.h"
#import "CLBRemoteObjectSynchronizer.h"
#import "CLBUser+Private.h"
#import "CLBErrorMessageOverlay.h"
#import "CLBConversationHeaderView.h"
#import "CLBConfigFetchScheduler.h"
#import "CLBRTSpinKitView.h"
#import "CLBImageLoader.h"
#import "CLBDependencyManager.h"
#import "CLBConfig.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "CLBFileUploadMessage.h"
#import "CLBSOImageBrowserView.h"
#import "CLBSOPhotoMessageCell.h"
#import "CLBSOActivityMessageCell.h"
#import "CLBImagePickerController.h"
#import "CLBConversationMonitor.h"
#import "CLBBuyViewController.h"
#import "CLBWebviewViewController.h"
#import "CLBPhotoConfirmationViewController.h"
#import "CLBStripeApiClient.h"
#import "CLBConversationActivity+Private.h"
#import "CLBRepliesView.h"
#import <UserNotifications/UserNotifications.h>
#import "CLBLocationService.h"
#import "CLBSettings.h"
#import "ClarabridgeChat+Private.h"
#import "CLBNavigationBar.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <SafariServices/SafariServices.h>
#import "CLBConversationViewControllerDelegate.h"

static BOOL didRegisterForRemoteNotifications = NO;
static BOOL conversationShown = NO;

static const int kSelectImageActionSheetTag = 1;
static const int kFailedImageActionSheetTag = 2;
static const int kTypingActivityTimeLimit = 10;
static const float kMessageBounceAnimationDelay = .15;
static const float kRepliesBounceAnimationDelay = .3;

typedef NS_ENUM(NSInteger, CLBBounceType) {
    CLBBounceTypeNone,
    CLBBounceTypeFromLeft,
    CLBBounceTypeFromRight
};

@interface CLBConversationViewController() < UIActionSheetDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, CLBBuyViewControllerDelegate, CLBRepliesViewDelegate, CLBLocationServiceDelegate, CLBPhotoConfirmationDelegate >

@property UINavigationBar* navBar;
@property NSString* convId;
@property CLBErrorMessageOverlay* errorMessageOverlay;
@property CLBConversationHeaderView* headerLabel;
@property BOOL kvoRegistered;
@property BOOL fayeErrorHidden;
@property NSTimer* errorBarTimer;
@property UIView* progressIndicatorView;
@property UIImage* defaultAvatar;
@property BOOL customerFetchAttempted;

@property UIStatusBarStyle statusBarStyle;
@property UIStatusBarStyle appStatusBarStyle;
@property(weak) CLBDependencyManager* dependencies;

@property NSMutableArray* pendingMessages;

@property CLBSOMessageCell* tappedCell;
@property CLBConversationActivity *typingActivity;
@property NSTimer *typingActivityTimer;

@property NSMutableArray *conversationMessages;
@property CLBLocationService *locationService;

@property NSArray<NSString *> *actionSheetButtons;
@property NSArray<NSString *> *allowedMenuItems;

@property BOOL newConversationLoading;

@end

@implementation CLBConversationViewController

+(BOOL)isConversationShown {
    return conversationShown;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeKVO];
}

-(instancetype)initWithDeps:(CLBDependencyManager *)deps {
    self = [super initWithAccentColor:deps.sdkSettings.conversationAccentColor userMessageTextColor:deps.sdkSettings.userMessageTextColor];
    if(self){
        _pendingMessages = [[NSMutableArray alloc] init];
        _statusBarStyle = deps.sdkSettings.conversationStatusBarStyle;
        _dependencies = deps;
        _defaultAvatar = [ClarabridgeChat getImageFromResourceBundle:@"defaultAvatar"];
        _locationService = deps.locationService;
        _allowedMenuItems = [deps.sdkSettings.allowedMenuItems copy];

        if(!deps.sdkSettings.requestPushPermissionOnFirstMessage){
            didRegisterForRemoteNotifications = YES;
        }
        
        _newConversationLoading = NO;
    }
    return self;
}

- (void)updateConversationId:(NSString *)conversationId {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeKVO];

    self.convId = conversationId;

    [self registerKVO];
    [self registerNotificationCenterObservers];
    [self reloadConversationMessages];
}

- (CLBConversation *)conversationObject {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(conversation:)]) {
        CLBConversation *conversation = [self.delegate conversation:self.convId];
        return conversation;
    }
    return nil;
}

-(void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = CLBSystemBackgroundColor();

    [self initNavBar];
    [self initErrorMessageOverlay];
    [self initProgressIndicator];

    CLBConfigFetchScheduler* configScheduler = self.dependencies.configFetchScheduler;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self registerNotificationCenterObservers];

    [self.tableView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.chatInputView.textView action:@selector(resignFirstResponder)]];

    self.headerLabel = [[CLBConversationHeaderView alloc] initWithColor:self.accentColor];

    [self.headerLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerTapped)]];

    if (configScheduler.config.validityStatus == CLBAppStatusUnknown) {
        [ClarabridgeChat fetchConfig];
    }

    self.locationService.delegate = self;

    [self registerKVO];
}

-(void)registerNotificationCenterObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchStatusChanged) name:CLBInitializationDidCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchStatusChanged) name:CLBInitializationDidFailNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchStatusChanged) name:CLBConversationMonitorDidChangeConnectionStatusNotification object:self.dependencies.conversationMonitor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMessagesWithDelay) name:CLBMessageUploadCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMessagesWithDelay) name:CLBMessageUploadFailedNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newMessagesReceived:) name:CLBConversationDidReceiveMessagesNotification object:self.conversationObject];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previousMessagesReceived:) name:CLBConversationDidReceivePreviousMessagesNotification object:self.conversationObject];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityReceived:) name:CLBConversationDidReceiveActivityNotification object:self.conversationObject];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageUploadDidComplete:) name:CLBConversationImageUploadCompletedNotification object:self.conversationObject];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageUploadProgressDidChange:) name:CLBConversationImageUploadProgressDidChangeNotification object:self.conversationObject];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(conversationDidStartImageUpload:) name:CLBConversationImageUploadDidStartNotification object:self.conversationObject];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileUploadDidStart:) name:CLBConversationFileUploadDidStartNotification object:self.conversationObject];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileUploadDidComplete:) name:CLBConversationFileUploadCompletedNotification object:self.conversationObject];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileUploadProgressDidChange:) name:CLBConversationFileUploadProgressDidChangeNotification object:self.conversationObject];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDidComplete:) name:CLBLoginDidCompleteNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadConversationDidStart:) name:CLBConversationLoadDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadConversationDidFinish:) name:CLBConversationLoadDidFinishNotification object:nil];
}

-(void)registerKVO {
    if(!self.kvoRegistered){
        CLBConversation *conversationObject = [self conversationObject];
        [conversationObject addObserver:self forKeyPath:@"messages" options:NSKeyValueObservingOptionNew context:nil];
        [conversationObject addObserver:self forKeyPath:@"conversationId" options:NSKeyValueObservingOptionOld context:nil];
        if (conversationObject) {
            self.kvoRegistered = YES;
        }
    }
}

-(void)removeKVO {
    if(self.kvoRegistered){
        [self.conversationObject removeObserver:self forKeyPath:@"messages"];
        [self.conversationObject removeObserver:self forKeyPath:@"conversationId"];
        self.kvoRegistered = NO;
    }
}

-(void)fetchStatusChanged {
    [self updateErrorMessage];

    BOOL initCompleted = self.dependencies.configFetchScheduler.config.validityStatus != CLBAppStatusUnknown;

    if (initCompleted) {
        if (!self.conversationObject.conversationStarted || [self.dependencies.conversationMonitor isConnected] || [self.dependencies.conversationMonitor isWaitingForConnection]) {
            [self hideProgressIndicator];
        }
    } else {
        [self hideProgressIndicator];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"conversationId"]){
        id oldValue = change[NSKeyValueChangeOldKey];
        if(oldValue == [NSNull null] && self.conversationObject.conversationStarted){
            [self hideErrorBarForSeconds:3];
        }

        return;
    }

    if([keyPath isEqualToString:@"messages"]) {
        [self reloadConversationMessages];
        if([change[NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeSetting) {
            CLBEnsureMainThread(^{
                [self updateHeaderWithType:[self hasPreviousMessages] ? CLBConversationHeaderTypeLoadMore : CLBConversationHeaderTypeConversationStart];
                [self refreshMessagesAndKeepOffset:YES];
            });
        }

        if([change[NSKeyValueChangeKindKey] intValue] != NSKeyValueChangeInsertion){
            return;
        }

        CLBMessage* newMessage = change[NSKeyValueChangeNewKey][0];

        if(!newMessage.isFromCurrentUser){
            [self clearCurrentTypingActivity];
            return;
        }

        if(self.loadStatus == CLBTableViewLoadStatusLoaded){
            if ([self.pendingMessages containsObject:newMessage]) {
                [self.pendingMessages removeObject:newMessage];
                [self reloadConversationMessages];
                [self refreshMessagesWithBounce:CLBBounceTypeNone];
            } else {
                [self refreshMessagesWithBounce:CLBBounceTypeFromRight];
            }
        }
    }
}

-(void)loginDidComplete:(NSNotification*)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeKVO];
    [self registerKVO];
    [self registerNotificationCenterObservers];
    [self reloadConversationMessages];
}

-(void)loadConversationDidStart:(NSNotification*)notification {
    self.newConversationLoading = YES;
    [self.conversationMessages removeAllObjects];

    CLBEnsureMainThread(^{
        self.tableView.alpha = 0.0f;
        self.progressIndicatorView.center = self.view.center;
        self.progressIndicatorView.alpha = 1.0;
        [self.view addSubview:self.progressIndicatorView];
    });
}

-(void)loadConversationDidFinish:(NSNotification*)notification {
    self.newConversationLoading = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideProgressIndicator];
        [self.progressIndicatorView removeFromSuperview];
        [self reloadConversationMessages];
        [self refreshMessagesAndKeepOffset:NO animateScrollToBottom:NO];
        [UIView animateWithDuration:0.3 animations:^{
            self.tableView.alpha = 1.0f;
        }];
    });
}

-(void)newMessagesReceived:(NSNotification*)notification {
    if (conversationShown && [self.delegate respondsToSelector:@selector(conversationViewController:didMarkAllAsReadInConversation:)]) {
        [self.delegate conversationViewController:self didMarkAllAsReadInConversation:self.conversationObject.conversationId];
    }

    NSArray* newMessages = notification.userInfo[CLBConversationNewMessagesKey];
    
    CLBBounceType b = CLBBounceTypeNone;
    if (newMessages.count == 1) {
        if ([[self messages] containsObject:newMessages[0]]) {
            b = CLBBounceTypeFromLeft;
        }
    }

    [self refreshMessagesWithBounce:b];
}

-(void)previousMessagesReceived:(NSNotification *)notification {
    if (notification.userInfo[@"error"] || [self hasPreviousMessages]) {
        [self updateHeaderWithType:CLBConversationHeaderTypeLoadMore];
    } else {
        [self updateHeaderWithType:CLBConversationHeaderTypeConversationStart];
    }
    self.loadStatus = CLBTableViewLoadStatusLoaded;
}

-(void)activityReceived:(NSNotification *)notification {
    CLBConversationActivity *activity = notification.userInfo[CLBConversationActivityKey];
    
    if ([CLBConversationActivityTypeConversationRead isEqualToString:activity.type]) {
        [self refreshMessages];
    } else if ([CLBConversationActivityTypeTypingStart isEqualToString:activity.type] || [CLBConversationActivityTypeTypingStop isEqualToString:activity.type]) {
        [self clearCurrentTypingActivity];
        
        if ([CLBConversationActivityTypeTypingStart isEqualToString:activity.type]) {
            self.typingActivity = activity;
            [self showTypingActivity];
        }
        
        [self refreshMessages];
    }
}

-(void)showTypingActivity {
    [self startTypingActivityTimer];
}

-(void)startTypingActivityTimer {
    [self clearTypingActivityTimer];

    self.typingActivityTimer = [NSTimer scheduledTimerWithTimeInterval:kTypingActivityTimeLimit
                                                                target:self
                                                              selector:@selector(typingActivityTimerDidFinish:)
                                                              userInfo:nil
                                                               repeats:NO];
}

-(void)typingActivityTimerDidFinish:(NSTimer *)timer {
    [self clearCurrentTypingActivity];
    [self refreshMessages];
    [self clearTypingActivityTimer];
}

-(void)clearTypingActivityTimer {
    if (self.typingActivityTimer) {
        [self.typingActivityTimer invalidate];
        self.typingActivityTimer = nil;
    }
}

-(void)clearCurrentTypingActivity {
    self.typingActivity = nil;
}

-(void)refreshMessagesWithDelay {
    [self reloadConversationMessages];

    CLBEnsureMainThread(^{
        // Add a little delay so it doesn't look jumpy
        [self performSelector:@selector(refreshMessages) withObject:nil afterDelay:1];
    });
}

-(void)refreshMessagesWithBounce:(CLBBounceType)bounce {
    CLBEnsureMainThread(^{
        [self refreshMessages];

        if(self.messages.count > 0 && bounce != CLBBounceTypeNone){
            NSInteger section = [self.tableView numberOfSections] - 1;
            
            if (section >= 0) {
                NSInteger row = [self.tableView numberOfRowsInSection:section] - 1;
                
                if (row >= 0) {
                    NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:section];
                    [self bounceCell:(CLBSOMessageCell*)[self.tableView cellForRowAtIndexPath:path] withBounce:bounce];
                }
            }
        }

        [self refreshRepliesViewWithBounce:bounce];
    });
}

-(void)bounceCell:(CLBSOMessageCell*)cell withBounce:(CLBBounceType)bounce {
    [self animateView:cell.containerView withBounce:bounce delay:kMessageBounceAnimationDelay];
}

-(void)animateView:(UIView *)view withBounce:(CLBBounceType)bounce delay:(CGFloat) delay {
    CGRect frame = view.frame;
    if (bounce == CLBBounceTypeFromRight) {
        view.layer.anchorPoint = CGPointMake(1.0, 0.5);
        view.layer.position = CGPointMake(round(frame.origin.x + frame.size.width), frame.origin.y + frame.size.height / 2);
    } else if (bounce == CLBBounceTypeFromLeft) {
        view.layer.anchorPoint = CGPointMake(0.0, 0.5);
        view.layer.position = CGPointMake(round(frame.origin.x), frame.origin.y + frame.size.height / 2);
    }

    view.transform = CGAffineTransformMakeScale(0.01, 0.01);

    [UIView animateWithDuration:0.65
                          delay:delay
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         view.transform = CGAffineTransformIdentity;
                     } completion:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self registerKVO];

    conversationShown = YES;

    [self startMonitoringNetwork];
    [self updateErrorMessage];

    if ([self.delegate respondsToSelector:@selector(conversationViewController:didMarkAllAsReadInConversation:)]) {
        [self.delegate conversationViewController:self didMarkAllAsReadInConversation:self.conversationObject.conversationId];
    }
    self.chatInputView.cancelAnimations = NO;

    if(self.isBeingPresented || self.isMovingToParentViewController){
        self.appStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
        [UIApplication sharedApplication].statusBarStyle = self.statusBarStyle;

        if([self.conversationObject.delegate respondsToSelector:@selector(conversation:didShowViewController:)]){
            [self.conversationObject.delegate conversation:self.conversationObject didShowViewController:self];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated {
    // Reload messages before call to super. Superclass will reload the tableview and needs recent data
    [self reloadConversationMessages];

    [super viewWillAppear:animated];

    if (self.isBeingPresented){
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[CLBLocalization localizedStringForKey:@"Done"] style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    }

    if(self.isBeingPresented || self.isMovingToParentViewController){
        if(CLBIsNetworkAvailable() && [self isAppValid] && !self.conversationObject.conversationStarted && !self.tabBarController && [CLBSOMessagingViewController isInputDisplayed]){
            self.chatInputView.cancelAnimations = YES;
            [self.chatInputView.textView becomeFirstResponder];
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // If the initial fetch is taking a long time, show the progress indicator
            if ((self.dependencies.conversationMonitor.isConnecting && ![self.dependencies.conversationMonitor isWaitingForConnection]) || [self.dependencies.configFetchScheduler isExecuting]) {
                [self showProgressIndicator];
            }
        });

        if([self.conversationObject.delegate respondsToSelector:@selector(conversation:willShowViewController:)]){
            [self.conversationObject.delegate conversation:self.conversationObject willShowViewController:self];
        }
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.chatInputView.textView resignFirstResponder];

    if(self.isBeingDismissed || self.isMovingFromParentViewController){
        [UIApplication sharedApplication].statusBarStyle = self.appStatusBarStyle;

        if([self.conversationObject.delegate respondsToSelector:@selector(conversation:willDismissViewController:)]){
            [self.conversationObject.delegate conversation:self.conversationObject willDismissViewController:self];
        }
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    conversationShown = NO;
    [self removeKVO];
    [self stopMonitoringNetwork];

    if(self.isBeingDismissed || self.isMovingFromParentViewController){
        if([self.conversationObject.delegate respondsToSelector:@selector(conversation:didDismissViewController:)]){
            [self.conversationObject.delegate conversation:self.conversationObject didDismissViewController:self];
        }
        [self clearTypingActivityTimer];
        [self clearCurrentTypingActivity];
    }
}

-(void)initNavBar {
    NSString* navBarTitle = [CLBLocalization localizedStringForKey:@"Messages"];

    if(self.navigationController){
        self.navigationItem.title = navBarTitle;
    }else{
        self.navBar = [[CLBNavigationBar alloc] init];

        if([UINavigationBar appearance].tintColor == nil){
            self.navBar.tintColor = CLBNavBarItemTextColor();
        }

        self.navigationItem.title = navBarTitle;

        [self.navBar pushNavigationItem:self.navigationItem animated:NO];

        [self.view addSubview:self.navBar];

        UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self.chatInputView.textView action:@selector(resignFirstResponder)];
        tapGesture.cancelsTouchesInView = NO;
        [self.navBar addGestureRecognizer:tapGesture];
    }
}

-(void)initErrorMessageOverlay {
    self.errorMessageOverlay = [[CLBErrorMessageOverlay alloc] init];
    self.errorMessageOverlay.alpha = 0.0;

    [self.view addSubview:self.errorMessageOverlay];
}

-(void)initProgressIndicator {
    UIView* spinnerView = [[CLBRTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleThreeBounce];
    spinnerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 2, 2);
    self.progressIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, spinnerView.frame.size.height)];
    [self.progressIndicatorView addSubview:spinnerView];
    spinnerView.center = CGPointMake(self.progressIndicatorView.frame.size.width / 2, spinnerView.frame.size.height / 2);
    self.progressIndicatorView.alpha = 0.0;
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.navBar.frame = CGRectMake(0, CLBSafeBoundsForView(self.view).origin.y, self.view.bounds.size.width, CLBNavBarHeight() - CLBOffsetForStatusBar());
    
    [self resizeErrorBar];
    [self adjustTableViewContentInset];

    self.headerLabel.frame = CGRectMake(0, 0, self.tableView.frame.size.width, CGFLOAT_MAX);
    [self.headerLabel sizeToFit];

    // Reset the tableHeaderView property so that it adjusts for the new frame
    self.tableView.tableHeaderView = self.headerLabel;

    [self refreshRepliesViewWithBounce:CLBBounceTypeNone];

    UIView* spinnerView = self.progressIndicatorView.subviews[0];
    spinnerView.center = CGPointMake(self.tableView.bounds.size.width / 2, spinnerView.frame.size.height / 2);
}

-(void)resizeErrorBar {
    CGFloat yCoord;
    if (CLBIsIOS11OrLater()) {
        yCoord = self.navigationController ? CLBSafeAreaInsetsForView(self.view).top : CGRectGetMaxY(self.navBar.frame);
    } else {
        yCoord = self.navigationController ? self.topLayoutGuide.length : CGRectGetMaxY(self.navBar.frame);
    }
    self.errorMessageOverlay.frame = CGRectMake(0, yCoord, self.view.bounds.size.width, 0);
    [self.errorMessageOverlay sizeToFit];
}

-(void)adjustTableViewContentInset {
    self.tableView.frame = CLBSafeBoundsForView(self.view);
    UIEdgeInsets contentInset = self.tableView.contentInset;
    UIEdgeInsets scrollIndicatorInset = self.tableView.scrollIndicatorInsets;

    if(self.errorMessageOverlay.alpha < 1){
        self.errorBannerHeight = 0;
        if (CLBIsIOS11OrLater()) {
            contentInset.top = self.navigationController ? 0 : (CLBNavBarHeight() - CLBOffsetForStatusBar());
        } else {
            contentInset.top = self.navigationController ? self.topLayoutGuide.length : CLBNavBarHeight();
        }
    }else{
        self.errorBannerHeight = CGRectGetHeight(self.errorMessageOverlay.frame);
        if (CLBIsIOS11OrLater()) {
            contentInset.top = (self.navigationController ? 0 : (CLBNavBarHeight() - CLBOffsetForStatusBar())) + self.errorBannerHeight;
        } else {
            contentInset.top = CGRectGetMaxY(self.errorMessageOverlay.frame);
        }
    }
    scrollIndicatorInset.top = contentInset.top;
    self.tableView.contentInset = contentInset;

    self.tableView.scrollIndicatorInsets = scrollIndicatorInset;
}

-(void)close {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return self.statusBarStyle;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.presentingViewController supportedInterfaceOrientations];
}

-(void)endEditing {
    [self.chatInputView.textView resignFirstResponder];
}

-(BOOL)resignFirstResponder {
    return [self.chatInputView.textView resignFirstResponder];
}

-(void)startMonitoringNetwork {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateErrorMessage) name:CLBReachabilityStatusChangedNotification object:nil];
}

-(void)stopMonitoringNetwork {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CLBReachabilityStatusChangedNotification object:nil];
}

-(void)updateHeaderWithType:(CLBConversationHeaderType)headerType {
    if (headerType != self.headerLabel.type) {
        CLBEnsureMainThread(^{
            [self.headerLabel updateHeaderWithType:headerType];
            [self.headerLabel sizeToFit];
            self.tableView.tableHeaderView = self.headerLabel;
        });
    }
}

-(void)headerTapped {
    [self fetchPreviousMessagesIfNeeded];
}

- (BOOL)hasPreviousMessages {
    if ([self.delegate respondsToSelector:@selector(conversationViewController:shouldLoadPreviousMessagesInConversation:)]) {
        return [self.delegate conversationViewController:self shouldLoadPreviousMessagesInConversation:self.conversationObject.conversationId];
    }

    return NO;
}

-(void)fetchPreviousMessagesIfNeeded {
    if ([self hasPreviousMessages] && self.loadStatus == CLBTableViewLoadStatusLoaded) {
        self.loadStatus = CLBTableViewLoadStatusFetchingPrevious;
        [self updateHeaderWithType:CLBConversationHeaderTypeLoading];

        if ([self.delegate respondsToSelector:@selector(conversationViewController:didLoadPreviousMessagesInConversation:)]) {
            [self.delegate conversationViewController:self didLoadPreviousMessagesInConversation:self.conversationObject.conversationId];
        }
    }
}

-(void)refreshRepliesViewWithBounce:(CLBBounceType)bounce {
    if ([self shouldShowRepliesView]) {
        [self showRepliesViewWithBounce:bounce];
    } else {
        self.tableView.tableFooterView = nil;
    }
}

-(BOOL)shouldShowRepliesView {
    if (self.loadStatus != CLBTableViewLoadStatusLoaded) {
        return NO;
    }

    if (self.conversationMessages && self.conversationMessages.count > 0) {
        CLBMessage *lastMessage = [self.conversationMessages lastObject];
        BOOL isFromAppMaker = !lastMessage.isFromCurrentUser;

        return isFromAppMaker && ([lastMessage hasReplies] || [lastMessage hasLocationRequest]);
    }

    return NO;
}

#pragma mark - SOMessaging data source

- (void)reloadConversationMessages {
    if (self.newConversationLoading) {
        return;
    }
    
    NSMutableArray* messages = [NSMutableArray arrayWithArray:[self.conversationObject mutableArrayValueForKey:@"messages"]];

    if (self.conversationObject.conversationStarted || messages.count > 0 || self.pendingMessages.count > 0) {
        [messages addObjectsFromArray:self.pendingMessages];

        [messages sortUsingComparator:^NSComparisonResult(CLBMessage* obj1, CLBMessage* obj2) {
            return [obj1.date compare:obj2.date];
        }];

        [self filterMessages:messages];

        self.conversationMessages = messages;
    }
}

-(void)filterMessages:(NSMutableArray *)messages {
    NSUInteger messageCount = messages.count;

    for(NSInteger i = messageCount - 1; i >= 0; i--) {
        CLBMessage *message = messages[i];
        BOOL isValidMessage = [message isKindOfClass:[CLBMessage class]];
        BOOL shouldRemoveMessage = i < messageCount - 1 && isValidMessage && [self isEmptyReplyMessage:message];
        if (shouldRemoveMessage) {
            [messages removeObjectAtIndex:i];
        } else if (isValidMessage) {
            if ([self.conversationObject.delegate respondsToSelector:@selector(conversation:willDisplayMessage:)]) {
                CLBMessage *mutatedMessage = [self.conversationObject.delegate conversation:self.conversationObject willDisplayMessage:[message copy]];
                mutatedMessage.isFromCurrentUser = message.isFromCurrentUser;
                message = mutatedMessage;
            }
            
            if (!message) {
                [messages removeObjectAtIndex:i];
            } else {
                [self filterActionsWithoutText:message];
                messages[i] = message;
            }
        }
    }
}

-(void)filterActionsWithoutText:(CLBMessage *)message {
    if (message.actions.count > 0) {
        message.actions = [self filteredActions:message.actions];
    }

    if (message.items.count > 0) {
        for (CLBMessageItem *item in message.items) {
            if (item.actions.count > 0) {
                item.actions = [self filteredActions:item.actions];
            }
        }
    }
}

-(NSArray<CLBMessageAction *> *)filteredActions:(NSArray *)actions {
    NSMutableArray *filteredActions = [NSMutableArray new];
    
    for (CLBMessageAction *action in actions) {
        if (action.text.length > 0) {
            [filteredActions addObject:action];
        }
    }
    
    return filteredActions;
}

-(BOOL)isEmptyReplyMessage:(CLBMessage *)message {
    NSString *trimmedText = message.text ? [message.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : @"";
    NSString *trimmedMediaUrl = message.mediaUrl ? [message.mediaUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : @"";
    return !message.isFromCurrentUser && ([message hasReplies] || [message hasLocationRequest]) && [trimmedText isEqualToString:@""] && [trimmedMediaUrl isEqualToString:@""];
}

- (NSMutableArray *)messages {
    if (!self.conversationMessages) {
        [self reloadConversationMessages];
    }
    return self.conversationMessages;
}

- (CLBConversationActivity *)conversationActivity {
    return self.typingActivity;
}

-(void)configureMessageCell:(CLBSOMessageCell *)cell forMessageAtIndex:(NSInteger)index {
    BOOL isActivityCell = [cell isKindOfClass:[CLBSOActivityMessageCell class]];

    if((index < 0 || index >= self.messages.count) && !isActivityCell){
        return;
    }

    id<CLBSOMessage> message = isActivityCell ? cell.message : self.messages[index];

    if(isActivityCell || !message.isFromCurrentUser){
        CLBImageLoader* avatarImageLoader = [ClarabridgeChat avatarImageLoader];
        UIImage* cachedAvatar = [avatarImageLoader cachedImageForUrl:message.avatarUrl];

        if(cachedAvatar){
            cell.userImage = cachedAvatar;
        }else{
            cell.userImage = self.defaultAvatar;

            if(message.avatarUrl){
                [avatarImageLoader loadImageForUrl:message.avatarUrl withCompletion:^(UIImage *image) {
                    if(image && [cell.message.avatarUrl isEqualToString:message.avatarUrl]){
                        [cell onImageLoaded:image];
                    }
                }];
            }
        }

        if (!isActivityCell) {
            [self fetchCreditCardInfoIfNecessary:message];
        }
    }
}

-(void)fetchCreditCardInfoIfNecessary:(id<CLBSOMessage>)message {
    CLBUser* user = self.conversationObject.user;

    if(self.customerFetchAttempted || !user.hasPaymentInfo || user.cardInfo != nil){
        return;
    }

    BOOL hasActions = message.actions.count > 0;
    NSUInteger offeredActionIndex = [message.actions indexOfObjectPassingTest:^BOOL(CLBMessageAction* obj, NSUInteger idx, BOOL* stop) {
        return [obj.state isEqualToString:CLBMessageActionStateOffered];
    }];

    if(hasActions && offeredActionIndex != NSNotFound){
        self.customerFetchAttempted = YES;

        CLBStripeApiClient* apiClient = [[CLBStripeApiClient alloc] initWithStripeHttpClient:nil clarabridgeChatHttpClient:self.dependencies.synchronizer.apiClient];
        [apiClient getCardInfoForUser:user completion:^(NSDictionary *cardInfo) {
            if(cardInfo){
                user.cardInfo = cardInfo;
            }
        }];
    }
}

- (void)registerForRemoteNotifications {
    if (self.delegate.isPushEnabled && !didRegisterForRemoteNotifications) {
        if(CLBIsIOS10OrLater()){
            [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[ClarabridgeChat userNotificationCategories]];

            UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound;
            [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
                // Ignore
            }];
        }else{
            UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge;

            UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:types categories:[ClarabridgeChat userNotificationCategories]];

            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        }

        didRegisterForRemoteNotifications = YES;
    }
}

- (void)showProgressIndicator {
    if(self.tableView.tableFooterView){
        return;
    }
    CLBEnsureMainThread(^{
        self.tableView.tableFooterView = self.progressIndicatorView;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [self.progressIndicatorView setAlpha:1.0];
    });
}

- (void)hideProgressIndicator {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];

        [self.progressIndicatorView setAlpha:0.0];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        if([self.tableView.tableFooterView isEqual:self.progressIndicatorView]) {
            self.tableView.tableFooterView = nil;
        }

        [UIView commitAnimations];
    });
}

- (void)updateErrorMessage {
    if (CLBIsNetworkAvailable()){
        if ([self.errorBarTimer isValid]) {
            return;
        }
        
        BOOL appValidationFailed = self.dependencies.configFetchScheduler.config.validityStatus == CLBAppStatusInvalid;

        if(appValidationFailed){
            [self showGenericError];
        }else if(self.conversationObject.conversationId == nil){
            if(self.dependencies.conversationMonitor.isConnected || self.fayeErrorHidden || !self.conversationObject.user.settings.realtime.enabled){
                [self setErrorAlpha:0.0];
            }else if(self.dependencies.conversationMonitor.isConnecting){
                if (self.dependencies.conversationMonitor.didConnectOnce) {
                    [self showReconnectingError];
                }
            }
        }else{
            [self setErrorAlpha:0.0];
        }
    }else if (![self shouldWorkOffline]){
        [self showNoNetworkError];
    }
}

-(void)showNoNetworkError {
    [self showError:[CLBLocalization localizedStringForKey:@"No Internet connection"]];
}

-(void)showReconnectingError {
    [self showError:[CLBLocalization localizedStringForKey:@"Reconnecting..."]];
}

-(void)showGenericError {
    [self showError:[CLBLocalization localizedStringForKey:@"Could not connect to server"]];
}

-(void)showError:(NSString *)errorText {
    [self setErrorText:errorText alpha:1.0];
}

-(void)showPostbackError {
    float currentAlpha = self.errorMessageOverlay.alpha;
    NSString* currentText = self.errorMessageOverlay.textLabel.text;
    NSString* localizedString = [CLBLocalization localizedStringForKey:@"An error occurred while processing your action. Please try again."];

    if ([currentText isEqualToString:localizedString]) {
        return;
    }

    [self setErrorText:localizedString alpha:1.0];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setErrorText:currentText alpha:currentAlpha];
    });
}

-(void)setErrorAlpha:(CGFloat)alpha {
    [self setErrorText:self.errorMessageOverlay.textLabel.text alpha:alpha];
}

-(void)setErrorText:(NSString*)text alpha:(CGFloat)alpha {
    CLBEnsureMainThread(^{
        [self.errorMessageOverlay.textLabel setText:text];
        [self resizeErrorBar];
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.errorMessageOverlay setAlpha:alpha];
            [self adjustTableViewContentInset];
        } completion:nil];
    });
}

#pragma mark - SOMessaging delegate

-(void)messageInputViewDidSelectMediaButton:(CLBSOMessageInputView *)inputView {
    if(![self canSendMessage]){
        return;
    }

    [self.chatInputView.textView resignFirstResponder];

    UIActionSheet* actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = self;
    actionSheet.tag = kSelectImageActionSheetTag;

    NSMutableArray<NSString *> *actions = [NSMutableArray new];
    
    if([self canShowCameraOption]){
        [actionSheet addButtonWithTitle:[CLBLocalization localizedStringForKey:@"Take Photo"]];
        [actions addObject:CLBMenuItemCamera];
    }
    if([self canShowGalleryOption]) {
        [actionSheet addButtonWithTitle:[CLBLocalization localizedStringForKey:@"Photo & Video Library"]];
        [actions addObject:CLBMenuItemGallery];
    }
    
    if ([self canShowDocumentsOption]) {
        [actionSheet addButtonWithTitle:[CLBLocalization localizedStringForKey:@"Upload Document"]];
        [actions addObject:CLBMenuItemDocument];
    }
    
    if([self canShowLocationOption]) {
        [actionSheet addButtonWithTitle:[CLBLocalization localizedStringForKey:@"Share Location"]];
        [actions addObject:CLBMenuItemLocation];
    }
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:[CLBLocalization localizedStringForKey:@"Cancel"]];
    
    self.actionSheetButtons = actions;

    [actionSheet showInView:self.view];
}

-(void)didReachTopOfMessages {
    [self fetchPreviousMessagesIfNeeded];
}

-(void)tableViewDidLoad {
    [self updateHeaderWithType:[self hasPreviousMessages] ? CLBConversationHeaderTypeLoadMore : CLBConversationHeaderTypeConversationStart];
    [self refreshRepliesViewWithBounce:CLBBounceTypeNone];
}

- (void)messageInputView:(CLBSOMessageInputView *)inputView didSendMessage:(NSString *)message {
    [self setErrorAlpha:0.0];

    if ([self.delegate respondsToSelector:@selector(conversationViewController:didSendMessageText:inConversation:)]) {
        [self.delegate conversationViewController:self didSendMessageText:message inConversation:self.conversationObject.conversationId];
    }

    [self registerForRemoteNotifications];
}

-(BOOL)messageInputView:(CLBSOMessageInputView *)inputView shouldSendMessage:(NSString *)message {
    return [self canSendMessage:message];
}

-(BOOL)shouldDisplayMediaButton {
    return [self canShowCameraOption] || [self canShowGalleryOption] || [self canShowDocumentsOption] || [self canShowLocationOption];
}

-(BOOL)isActionAllowed:(NSString *)actionName {
    return [self.allowedMenuItems containsObject:actionName];
}

-(BOOL)canShowCameraOption {
    if (![self isActionAllowed:CLBMenuItemCamera]) {
        return NO;
    }
    
    BOOL isCameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];

    if (![self isIOS10OrLater]) {
        return isCameraAvailable;
    }

    BOOL isCameraUsageDescriptionProvided = [[[NSBundle mainBundle] infoDictionary]objectForKey:@"NSCameraUsageDescription"] != nil;
    
    BOOL isPhotoLibraryAddUsageDescriptionProvided = [self isIOS11OrLater] ? [[[NSBundle mainBundle] infoDictionary]objectForKey:@"NSPhotoLibraryAddUsageDescription"] != nil : YES;

    return isCameraAvailable && isCameraUsageDescriptionProvided && isPhotoLibraryAddUsageDescriptionProvided;
}

-(BOOL)canShowGalleryOption {
    if (![self isActionAllowed:CLBMenuItemGallery]) {
        return NO;
    }
    
    if (![self isIOS10OrLater]) {
        return YES;
    }

    BOOL isPhotoLibraryUsageDescriptionProvided = [[[NSBundle mainBundle] infoDictionary]objectForKey:@"NSPhotoLibraryUsageDescription"] != nil;

    return isPhotoLibraryUsageDescriptionProvided;
}

-(BOOL)canShowDocumentsOption {
    if (![self isActionAllowed:CLBMenuItemDocument]) {
        return NO;
    }
    
    if (CLBIsIOS11OrLater()) {
        return YES;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return fileManager.ubiquityIdentityToken != nil;
}

-(BOOL)canShowLocationOption {
    if (![self isActionAllowed:CLBMenuItemLocation]) {
        return NO;
    }
    
    return [self.locationService isLocationUsageDescriptionProvided];
}

-(BOOL)isIOS10OrLater {
    return CLBIsIOS10OrLater();
}

-(BOOL)isIOS11OrLater {
    return CLBIsIOS11OrLater();
}

- (BOOL)isAppValid {
    if ([self.delegate respondsToSelector:@selector(conversationViewControllerCanCheckIsAppValid:)]) {
        return [self.delegate conversationViewControllerCanCheckIsAppValid:self];
    }

    return NO;
}

- (BOOL)shouldWorkOffline {
    if ([self.delegate respondsToSelector:@selector(conversationViewControllerShouldWorkOffline:)]) {
        return [self.delegate conversationViewControllerShouldWorkOffline:self];
    }

    return NO;
}

- (BOOL)canSendMessage {
    BOOL canSendMessage = NO;
    if ([self.delegate respondsToSelector:@selector(conversationViewControllerCanSendMessage:)]) {
        canSendMessage = [self.delegate conversationViewControllerCanSendMessage:self];
    }

    if (!canSendMessage) {
        [self shakeErrorBar];
    }

    return canSendMessage;
}

- (BOOL)canSendMessage:(NSString*)message {
    if ([self.delegate respondsToSelector:@selector(conversationViewController:canSendMessage:)]) {
        return [self.delegate conversationViewController:self canSendMessage:message];
    }

    return NO;
}

-(void)shakeErrorBar {
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.errorMessageOverlay.textLabel.transform = CGAffineTransformMakeTranslation(0, 3);
                     }
                     completion:^(BOOL finished) {
                         if(finished){
                             [UIView animateWithDuration:0.1
                                                   delay:0
                                                 options:UIViewAnimationOptionBeginFromCurrentState
                                              animations:^{
                                                  self.errorMessageOverlay.textLabel.transform = CGAffineTransformIdentity;
                                              }
                                              completion:nil];
                         }
                     }];
}

-(void)retryMessage:(NSObject<CLBSOMessage>*)message forCell:(CLBSOMessageCell *)cell {
    BOOL didMessageFail = message.failed;
    if(!didMessageFail){
        return;
    }

    if([message isKindOfClass:[CLBMessage class]]){
        if([CLBMessageTypeLocation isEqualToString:message.type]) {
            [self retryLocationMessage:(CLBMessage *)message];
        } else if([self canSendMessage:message.text]){
            [self retryMessage:(CLBMessage*)message];
        }
    }else{
        if([self canSendMessage]){
            [self.pendingMessages removeObject:message];
            if ([message.type isEqualToString:CLBMessageTypeImage]) {
                [self sendImage:message.image];
            } else if ([message.type isEqualToString:CLBMessageTypeFile]) {
                [self sendFile:[NSURL URLWithString:message.mediaUrl]];
            }
            [self reloadConversationMessages];
        }
    }
}

-(void)retryLocationMessage:(CLBMessage *)message {
    if([message hasCoordinates]) {
        [self retryMessage:message];
    } else {
        message.uploadStatus = CLBMessageUploadStatusUnsent;
        [self.locationService requestCurrentLocationForMessage:message];
    }
}

- (void)retryMessage:(CLBMessage *)message {
    if ([self.delegate respondsToSelector:@selector(conversationViewController:didRetryMessage:inConversation:)]) {
        [self.delegate conversationViewController:self didRetryMessage:message inConversation:self.conversationObject.conversationId];
    }
}

-(void)messageCell:(CLBSOMessageCell *)cell didSelectWebview:(CLBMessageAction *)action {
    CLBWebviewViewController *webviewViewController = [[CLBWebviewViewController alloc] initWithAction:action];
    webviewViewController.modalPresentationStyle = UIModalPresentationCustom;
    webviewViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:webviewViewController animated:YES completion:nil];
}

-(void)messageCell:(CLBSOMessageCell *)cell didSelectLink:(NSURL *)link {
    CLBOpenExternalURL(link);
}

-(void)messageCell:(CLBSOMessageCell *)cell didSelectMediaUrl:(NSString *)mediaUrl {   
    NSURL* url = [NSURL URLWithString:mediaUrl];
    
    if (!url) {
        return;
    }
    
    if (@available(iOS 9.0, *)) {
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
        safariViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [self presentViewController:safariViewController animated:YES completion:nil];
    } else if ([[UIApplication sharedApplication] canOpenURL:url]) {
        CLBOpenExternalURL(url);
    }
}

- (void)messageCell:(CLBSOMessageCell *)cell didSelectPostback:(CLBMessageAction *)action {
    if ([self.delegate respondsToSelector:@selector(conversationViewController:didSendPostback:inConversation:completion:)]) {
        [self.delegate conversationViewController:self didSendPostback:action inConversation:self.conversationObject.conversationId completion:^(NSError * _Nullable error) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self refreshMessages];

                if (error) {
                    [self showPostbackError];
                }
            });
        }];
    }

    [self refreshMessages];
}

-(void)messageCell:(CLBSOMessageCell *)cell didSelectAction:(CLBMessageAction *)action {
    if([self.conversationObject.delegate respondsToSelector:@selector(conversation:shouldHandleMessageAction:)]){
        if(![self.conversationObject.delegate conversation:self.conversationObject shouldHandleMessageAction:action]){
            return;
        }
    }

    if([action.type isEqualToString:CLBMessageActionTypeBuy]){
        if (self.dependencies.config.stripeEnabled) {
            [self presentStripeViewControllerForAction:action message:((CLBMessage *)cell.message)];
        } else {
            [self messageCell:cell didSelectLink:action.uri];
        }
    }else if([action.type isEqualToString:CLBMessageActionTypePostback]){
        [self messageCell:cell didSelectPostback:action];
    }else if([action.type isEqualToString:CLBMessageActionTypeWebview]) {
        [self messageCell:cell didSelectWebview:action];
    }else if([action.type isEqualToString:CLBMessageActionTypeLink]) {
        [self messageCell:cell didSelectLink:action.uri];
    }else if(action.fallback) {
        [self messageCell:cell didSelectLink:action.fallback];
    }else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:[CLBLocalization localizedStringForKey:@"Error"]
                                                                       message:[CLBLocalization localizedStringForKey:@"Unsupported action type"]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:[CLBLocalization localizedStringForKey:@"Dismiss"] style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

-(void)presentStripeViewControllerForAction:(CLBMessageAction *) action message:(CLBMessage *)message {
    CLBUser* user = self.conversationObject.user;
    CLBStripeApiClient* stripeApiClient = [CLBStripeApiClient newWithDependencies:self.dependencies];

    CLBBuyViewController* buyViewController = [[CLBBuyViewController alloc] initWithAction:action user:user apiClient:stripeApiClient];
    buyViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    buyViewController.accentColor = self.accentColor;
    buyViewController.message = message;
    buyViewController.delegate = self;

    [self.chatInputView.textView resignFirstResponder];

    BOOL requiresCustomAnimation = user.hasPaymentInfo;

    [self presentViewController:buyViewController animated:!requiresCustomAnimation completion:nil];
}

-(void)messageCell:(CLBSOMessageCell *)cell didTapImage:(UIImage *)tappedImage onMessageItemView:(CLBMessageItemView *)messageItemView {
    UIImage* image = tappedImage ?: [[ClarabridgeChat avatarImageLoader] cachedImageForUrl:messageItemView.viewModel.mediaUrl];
    if (image) {
        [self showPreviewForImage:image fromView:messageItemView.imageView inView:messageItemView];
    } else {
        [messageItemView loadImage];
    }
}

- (void)messageCellDidTapMedia:(CLBSOPhotoMessageCell *)cell {
    if(cell.message.failed){
        UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:[CLBLocalization localizedStringForKey:@"Cancel"]
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:[CLBLocalization localizedStringForKey:@"Resend"],
                                      [CLBLocalization localizedStringForKey:@"View Image"], nil];
        actionSheet.tag = kFailedImageActionSheetTag;
        self.tappedCell = cell;

        [self.chatInputView.textView resignFirstResponder];
        [actionSheet showInView:self.view];
    }else{
        UIImage* image = cell.message.image ?: [[ClarabridgeChat avatarImageLoader] cachedImageForUrl:cell.message.mediaUrl];
        if(image) {
            [self showPreviewForImage:image fromView:cell.containerView inView:cell];
        }else{
            [cell reloadImage:YES];
        }
    }
}

-(void)showPreviewForImage:(UIImage*)image fromView:(UIView *)containerView inView:(UIView *)superview {
    self.imageBrowser = [[CLBSOImageBrowserView alloc] init];
    self.imageBrowser.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    self.imageBrowser.image = image;

    self.imageBrowser.startFrame = [superview convertRect:containerView.frame toView:self.view];

    [self.chatInputView.textView resignFirstResponder];
    [self.imageBrowser showInView:self.view];
}

-(void)didSelectLocationRequest:(CLBMessageAction *)action {
    [self requestLocation:action];
}

- (void)didSelectReply:(CLBMessageAction *)action {
    if([self.delegate respondsToSelector:@selector(conversationViewController:didSendMessageFromAction:inConversation:)]) {
        [self.delegate conversationViewController:self didSendMessageFromAction:action inConversation:self.conversationObject.conversationId];
    }
}

-(void)requestLocation:(CLBMessageAction *)action {
    if ([self.locationService canRequestCurrentLocation]) {
        CLBMessage *message = [[CLBMessage alloc] initWithCoordinates:[[CLBCoordinates alloc] init] payload:action.payload metadata:action.metadata];
        message.isFromCurrentUser = YES;
        [self.locationService requestCurrentLocationForMessage:message];
    } else {
        [self showNoLocationPermissionError];
    }
}

-(void)locationService:(CLBLocationService *)locationService didStartLocationRequestforMessage:(CLBMessage *)message {
    if (![self.pendingMessages containsObject:message]) {
        [self.pendingMessages addObject:message];
    }
    [self reloadConversationMessages];
    [self refreshMessagesWithBounce:CLBBounceTypeFromRight];
}

-(void)locationService:(CLBLocationService *)locationService didReceiveAuthorizationResponse:(BOOL)granted {
    if (!granted) {
        [self showNoLocationPermissionError];
    }
}

-(void)locationService:(CLBLocationService *)locationService didFailWithError:(NSError *)error forMessage:(CLBMessage *)message {
    message.uploadStatus = CLBMessageUploadStatusFailed;

    if (error.code == CLBMissingLocationUsageDescriptionError) {
        NSLog(@"<CLARABRIDGECHAT::ERROR> No usage description for location services provided. Make sure to add either NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription in your app's Info.plist. Error : %@", error);

        if(![self.pendingMessages containsObject:message]) {
            [self.pendingMessages addObject:message];
            [self reloadConversationMessages];
            [self refreshMessagesWithBounce:CLBBounceTypeFromRight];
            return;
        }
    }

    [self refreshMessagesWithBounce:CLBBounceTypeNone];
}

- (void)locationService:(CLBLocationService *)locationService didReceiveCoordinates:(CLBCoordinates *)coordinates forMessage:(CLBMessage *)message {
    if ([self.delegate respondsToSelector:@selector(conversationViewController:didSendMessage:inConversation:)]) {
        [self.delegate conversationViewController:self didSendMessage:message inConversation:self.conversationObject.conversationId];
    }
}

-(void)requestPhotoPermission:(void(^)(void))completion {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if(status == PHAuthorizationStatusAuthorized){
            completion();
        }else{
            [self showNoPhotoPermissionError];
        }
    }];
}

-(void)requestCameraPermission:(void(^)(void))completion {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            completion();
        } else {
            [self showNoCameraPermissionError];
        }
    }];
}

-(void)showRepliesViewWithBounce:(CLBBounceType)bounce {
    if ([self shouldShowRepliesView]) {
        CLBRepliesView *repliesView = [[CLBRepliesView alloc] initWithFrame:CGRectMake(0, self.tableView.contentSize.height, self.tableView.frame.size.width, 0) color:self.accentColor];
        repliesView.delegate = self;
        CLBMessage *lastMessage = [self.messages lastObject];
        [repliesView setReplies:lastMessage.actions];
        [repliesView sizeToFit];
        self.tableView.tableFooterView = repliesView;
        self.tableView.tableFooterView.hidden = self.loadStatus != CLBTableViewLoadStatusLoaded;

        if (bounce != CLBBounceTypeNone) {
            [self animateView:repliesView withBounce:bounce delay:kRepliesBounceAnimationDelay];
        }

        [self.tableView scrollRectToVisible:[self.tableView convertRect:self.tableView.tableFooterView.bounds fromView:self.tableView.tableFooterView] animated:YES];
    }
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(actionSheet.tag == kFailedImageActionSheetTag){
        if(buttonIndex == 0){
            [self retryMessage:self.tappedCell.message forCell:self.tappedCell];
        }else if(buttonIndex == 1){
            [self showPreviewForImage:self.tappedCell.message.image fromView:((CLBSOPhotoMessageCell *)self.tappedCell).mediaImageView inView:self.tappedCell];
        }
        self.tappedCell = nil;
    }else{
        if(buttonIndex == actionSheet.cancelButtonIndex){
            self.tappedCell = nil;
            return;
        }
        
        NSString *action = self.actionSheetButtons[buttonIndex];

        if ([action isEqualToString:CLBMenuItemCamera]) {
            [self requestCameraPermission:^{
                CLBEnsureMainThread(^{
                    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
                    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
                    imagePicker.delegate = self;
                    
                    [self presentViewController:imagePicker animated:YES completion:nil];
                });
            }];
        } else if ([action isEqualToString:CLBMenuItemGallery]) {
            [self requestPhotoPermission:^{
                CLBEnsureMainThread(^{
                    UIImagePickerController* imagePicker = [[CLBImagePickerController alloc] init];
                    imagePicker.delegate = self;
                    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    imagePicker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
                    [self presentViewController:imagePicker animated:YES completion:nil];
                });
            }];
        } else if ([action isEqualToString:CLBMenuItemDocument]) {
            UIDocumentPickerViewController *documentPickerViewController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[(NSString *)kUTTypeData] inMode:UIDocumentPickerModeImport];
            documentPickerViewController.delegate = self;
            [self presentViewController:documentPickerViewController animated:YES completion:nil];
        } else if ([action isEqualToString:CLBMenuItemLocation]) {
            [self requestLocation:nil];
        }
        
    }
}

-(void)conversationDidStartImageUpload:(NSNotification*)notification {
    UIImage* image = notification.userInfo[CLBConversationImageKey];

    CLBFileUploadMessage* uploadMessage = [[CLBFileUploadMessage alloc] initWithImage:image];
    [self.pendingMessages addObject:uploadMessage];
    [self reloadConversationMessages];
    [self refreshMessagesWithBounce:CLBBounceTypeFromRight];
}

-(CLBFileUploadMessage*)imageUploadForImage:(UIImage*)image {
    NSUInteger index = [self.pendingMessages indexOfObjectWithOptions:0 passingTest:^BOOL(NSObject* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj isKindOfClass:[CLBFileUploadMessage class]] && ((CLBFileUploadMessage *)obj).image == image;
    }];

    if(index == NSNotFound){
        return nil;
    }else{
        return self.pendingMessages[index];
    }
}

-(CLBFileUploadMessage*)fileUploadForFile:(NSURL *)file {
    NSUInteger index = [self.pendingMessages indexOfObjectWithOptions:0 passingTest:^BOOL(NSObject* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj isKindOfClass:[CLBFileUploadMessage class]] && [((CLBFileUploadMessage *)obj).mediaUrl isEqualToString:[file.absoluteString stringByRemovingPercentEncoding]];
    }];
    
    if(index == NSNotFound){
        return nil;
    }else{
        return self.pendingMessages[index];
    }
}

-(void)imageUploadProgressDidChange:(NSNotification*)notification {
    UIImage* image = notification.userInfo[CLBConversationImageKey];

    CLBFileUploadMessage* uploadMessage = [self imageUploadForImage:image];
    uploadMessage.progress = [notification.userInfo[CLBConversationProgressKey] doubleValue];
}

-(void)imageUploadDidComplete:(NSNotification*)notification {
    UIImage* image = notification.userInfo[CLBConversationImageKey];
    NSError* error = notification.userInfo[CLBConversationErrorKey];

    CLBFileUploadMessage* uploadMessage = [self imageUploadForImage:image];

    if (error) {
        [self handleFileUploadError:error forUploadMessage:uploadMessage];
    }else{
        CLBMessage* message = notification.userInfo[CLBConversationMessageKey];
        [self.pendingMessages removeObject:uploadMessage];
        [self reloadConversationMessages];

        [[ClarabridgeChat avatarImageLoader] cacheImage:image forUrl:message.mediaUrl];
    }

    [self refreshMessagesWithBounce:CLBBounceTypeNone];
}

-(void)fileUploadDidStart:(NSNotification*)notification {
    NSURL* file = notification.userInfo[CLBConversationFileKey];
    long long fileSize = CLBSizeForFile(file);
    
    CLBFileUploadMessage *uploadMessage = [[CLBFileUploadMessage alloc] initWithMediaUrl:[file.absoluteString stringByRemovingPercentEncoding]];
    uploadMessage.mediaSize = [NSNumber numberWithLongLong:fileSize];
    BOOL isImage = [CLBContentTypeForPathExtension(file.pathExtension) hasPrefix:@"image"];
    
    uploadMessage.type = isImage ? CLBMessageTypeImage : CLBMessageTypeFile;
    
    [self.pendingMessages addObject:uploadMessage];
    [self reloadConversationMessages];
    [self refreshMessagesWithBounce:CLBBounceTypeFromRight];
}

-(void)fileUploadProgressDidChange:(NSNotification*)notification {
    NSURL *file = notification.userInfo[CLBConversationFileKey];
    
    CLBFileUploadMessage *uploadMessage = [self fileUploadForFile:file];
    uploadMessage.progress = [notification.userInfo[CLBConversationProgressKey] doubleValue];
}

-(void)fileUploadDidComplete:(NSNotification*)notification {
    NSURL *file = notification.userInfo[CLBConversationFileKey];
    NSError *error = notification.userInfo[CLBConversationErrorKey];

    CLBFileUploadMessage *uploadMessage = [self fileUploadForFile:file];

    if (error) {
        [self handleFileUploadError:error forUploadMessage:uploadMessage];
    } else {
        CLBMessage *message = notification.userInfo[CLBConversationMessageKey];
        [self handleFileUpload:message forUploadMessage:uploadMessage];
    }

    [self refreshMessagesWithBounce:CLBBounceTypeNone];
}

-(void)handleFileUploadError:(NSError *)error forUploadMessage:(CLBFileUploadMessage *)uploadMessage {    
    if ([CLBFailedUpload isRetryableUploadError:error]) {
        uploadMessage.failed = YES;
    } else {
        [self.pendingMessages removeObject:uploadMessage];
        [self reloadConversationMessages];
        NSString *errorMessage = error.userInfo[CLBErrorDescriptionIdentifier] ?: [CLBLocalization localizedStringForKey:@"Invalid file"];
        [self showErrorBarWithMessage:errorMessage forSeconds:3];
    }
}

-(void)handleFileUpload:(CLBMessage *)message forUploadMessage:(CLBFileUploadMessage *)uploadMessage {
    [self.pendingMessages removeObject:uploadMessage];
    [self reloadConversationMessages];
    
    if ([uploadMessage.type isEqualToString:CLBMessageTypeImage]) {
        UIImage *cachedImage = [[ClarabridgeChat avatarImageLoader] cachedImageForUrl:uploadMessage.mediaUrl];
        if (cachedImage) {
            [[ClarabridgeChat avatarImageLoader] cacheImage:cachedImage forUrl:message.mediaUrl];
        }
    }
}

- (void)sendImage:(UIImage*)image {
    if ([self.delegate respondsToSelector:@selector(conversationViewController:didSendImage:inConversation:)]) {
        [self.delegate conversationViewController:self didSendImage:image inConversation:self.conversationObject.conversationId];
    }
}

-(void)checkPhotoPermissionAndShowError {
    if([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized){
        [self showGenericPhotosError];
    }else{
        [self showNoPhotoPermissionError];
    }
}

-(void)showNoPhotosError {
    [self showErrorWithTitle:@"No Photos Found" description:@"Your photo library seems to be empty." linkToSettings:NO];
}

-(void)showNoPhotoPermissionError {
    [self showErrorWithTitle:@"Can't Access Photos" description:@"Make sure to allow photos access for this app in your privacy settings." linkToSettings:YES];
}

-(void)showNoCameraPermissionError {
    [self showErrorWithTitle:@"Can't Access Camera" description:@"Make sure to allow camera access for this app in your privacy settings." linkToSettings:YES];
}

-(void)showGenericPhotosError {
    [self showErrorWithTitle:@"Can't Retrieve Photo" description:@"Please try again or select a new photo." linkToSettings:NO];
}

-(void)showNoLocationPermissionError {
    [self showErrorWithTitle:@"Can't Access Location" description:@"Make sure to allow location access for this app in your privacy settings." linkToSettings:YES];
}

-(void)showErrorWithTitle:(NSString*)title description:(NSString*)description linkToSettings:(BOOL)linkToSettings {
    CLBEnsureMainThread(^{
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:[CLBLocalization localizedStringForKey:title]
                                                     message:[CLBLocalization localizedStringForKey:description]
                                                    delegate:self
                                           cancelButtonTitle:[CLBLocalization localizedStringForKey:@"Dismiss"]
                                           otherButtonTitles:linkToSettings ? [CLBLocalization localizedStringForKey:@"Settings"] : nil, nil];
        [av show];
    });
}

-(void)sendLatestPictureWithConfirmation:(BOOL)showConfirmation {
    [self requestPhotoPermission:^{
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];

        if(fetchResult.count == 0){
            [self showNoPhotosError];
            return;
        }

        PHAsset *lastAsset = [fetchResult lastObject];

        PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
        options.synchronous = false;
        options.version  = PHImageRequestOptionsVersionCurrent;

        CLBEnsureMainThread(^{
            [[PHImageManager defaultManager] requestImageForAsset:lastAsset
                                                       targetSize:self.view.bounds.size
                                                      contentMode:PHImageContentModeAspectFill
                                                          options:options
                                                    resultHandler:^(UIImage *result, NSDictionary *info) {
                                                        if([info[PHImageResultIsDegradedKey] integerValue] == 0){
                                                            if (showConfirmation) {
                                                                [self showConfirmationAlertForImage:result];
                                                            } else {
                                                                [self sendImage:result];
                                                            }
                                                        }
                                                    }];
        });
    }];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage* image = info[UIImagePickerControllerOriginalImage];
        
        if(picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            [self dismissViewControllerAnimated:YES completion:nil];
            
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }else{
            [self dismissViewControllerAnimated:YES completion:^{
                [self showConfirmationAlertForImage:image];
            }];
        }
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *fileLocation = info[UIImagePickerControllerMediaURL];
        
        [self sendFile:fileLocation];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// For iOS 8 - 10
-(void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    [self sendFile:url];
}

-(void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    [self sendFile:urls[0]];
}

- (void)sendFile:(NSURL *)fileLocation {
    if ([self.delegate respondsToSelector:@selector(conversationViewController:didCheckForErrorForFileURL:inConversation:)]) {
        NSString *errorMessage = [self.delegate conversationViewController:self didCheckForErrorForFileURL:fileLocation inConversation:self.conversationObject.conversationId];

        if (errorMessage) {
            [self showErrorBarWithMessage:errorMessage forSeconds:3];
            return;
        }
    }

    if ([self.delegate respondsToSelector:@selector(conversationViewController:didSendFileURL:inConversation:)]) {
        [self.delegate conversationViewController:self didSendFileURL:fileLocation inConversation:self.conversationObject.conversationId];
    }
}

-(void)showConfirmationAlertForImage:(UIImage *)image {
    CLBPhotoConfirmationViewController *photoConfirmationViewController = [[CLBPhotoConfirmationViewController alloc] initWithImage:image title:[CLBLocalization localizedStringForKey:@"Confirm Photo"]];
    photoConfirmationViewController.delegate = self;
    photoConfirmationViewController.modalPresentationStyle = UIModalPresentationCustom;
    photoConfirmationViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:photoConfirmationViewController animated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)image:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if(error){
        [self checkPhotoPermissionAndShowError];
    }else{
        [self sendLatestPictureWithConfirmation:NO];
    }
}

#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex != alertView.cancelButtonIndex){
        CLBOpenExternalURL([NSURL URLWithString:UIApplicationOpenSettingsURLString]);
    }
}

-(void)hideErrorBar {
    CLBEnsureMainThread(^{
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.errorMessageOverlay setAlpha:0.0];
            [self adjustTableViewContentInset];
        } completion:nil];
    });
}


-(void)showErrorBarWithMessage:(NSString *)errorMessage forSeconds:(int)seconds {
    CLBEnsureMainThread(^{
        [self showError:errorMessage];
        [self.errorBarTimer invalidate];
    });
    
    self.errorBarTimer = [NSTimer scheduledTimerWithTimeInterval:seconds
                                                          target:self
                                                        selector:@selector(hideErrorBar)
                                                        userInfo:nil
                                                         repeats:NO];
}

-(void)showErrorBar {
    CLBEnsureMainThread(^{
        self.fayeErrorHidden = NO;
        [self updateErrorMessage];
    });
}

-(void)hideErrorBarForSeconds:(int)seconds {
    CLBEnsureMainThread(^{
        [self.errorMessageOverlay setAlpha:0.0];
        [self adjustTableViewContentInset];
        [self.errorBarTimer invalidate];

        self.errorBarTimer = [NSTimer scheduledTimerWithTimeInterval:seconds
                                                              target:self
                                                            selector:@selector(showErrorBar)
                                                            userInfo:nil
                                                             repeats:NO];

        self.fayeErrorHidden = YES;
    });
}

-(void)applicationWillEnterForeground:(NSNotification*)notification {
    [self hideErrorBarForSeconds:3];
}

-(void)buyViewControllerDidDismissWithPurchase:(CLBBuyViewController *)viewController {
    NSArray<CLBMessage*>* messages = self.conversationObject.messages;

    // In case the conversation list has changed, find back the equivalent objects in the current list
    CLBMessage* message = [messages objectAtIndex:[messages indexOfObject:viewController.message]];
    CLBMessageAction* action = [message.actions objectAtIndex:[message.actions indexOfObject:viewController.action]];
    
    if (!action && message.items.count > 0) {
        for (CLBMessageItem *item in message.items) {
            if (item.actions.count > 0) {
                int actionIndex = (int)[item.actions indexOfObject:viewController.action];
                
                if (actionIndex >= 0 && actionIndex != NSNotFound) {
                    action = item.actions[actionIndex];
                    break;
                }
            }
        }
    }

    action.state = CLBMessageActionStatePaid;
    [self.conversationObject saveToDisk];
    [self reloadConversationMessages];
    [self refreshMessages];
}

#pragma mark - CLBRepliesViewDelegate

-(void)repliesView:(CLBRepliesView *) view didSelectReply:(CLBMessageAction *)action; {
    if ([action.type isEqualToString:CLBMessageActionTypeLocationRequest]) {
        [self didSelectLocationRequest:action];
    } else {
        [self didSelectReply:action];
    }
}

#pragma mark - CLBPhotoConfirmationDelegate

-(void)userDidConfirmPhoto:(UIImage *)image {
    [self sendImage:image];
}

#pragma mark - Keyboard
-(void)keyboardShown:(NSNotification*)notification {
    if ([self isPresentedAsSubview]) {
        [UIView setAnimationsEnabled:NO];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[CLBLocalization localizedStringForKey:@"Done"] style:UIBarButtonItemStylePlain target:self action:@selector(resignFirstResponder)];
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName:CLBNavBarItemTextColor()} forState:UIControlStateNormal];
        [UIView setAnimationsEnabled:YES];
    }
}

-(void)keyboardHidden:(NSNotification*)notification {
    if ([self isPresentedAsSubview]) {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

-(BOOL)isPresentedAsSubview {
    return self.tabBarController || [[UIScreen mainScreen] bounds].size.height - CGRectGetMaxY(self.view.frame) > 0;
}

#pragma mark - CLBSOMessageInputViewDelegate

-(void)inputViewDidBeginTyping:(CLBSOMessageInputView *)inputView {
    if ([self.delegate respondsToSelector:@selector(conversationViewController:didBeginTypingInConversation:)]) {
        [self.delegate conversationViewController:self didBeginTypingInConversation:self.conversationObject.conversationId];
    }
}

-(void)inputViewDidFinishTyping:(CLBSOMessageInputView *)inputView {
    if ([self.delegate respondsToSelector:@selector(conversationViewController:didFinishTypingInConversation:)]) {
        [self.delegate conversationViewController:self didFinishTypingInConversation:self.conversationObject.conversationId];
    }
}

@end
