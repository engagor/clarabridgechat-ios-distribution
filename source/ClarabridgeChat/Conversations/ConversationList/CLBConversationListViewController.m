//
//  CLBConversationListViewController.m
//  ClarabridgeChat
//
//  Created by Thaciana Lima on 20/05/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBConversationListViewController+Private.h"
#import "ClarabridgeChat+Private.h"
#import "CLBUtility.h"
#import "CLBLocalization.h"
#import "CLBConversationListViewModel.h"
#import "CLBEmptyListView.h"
#import "CLBDependencyManager+Private.h"
#import "CLBConversationViewModel.h"
#import "CLBConversationListTableViewCell.h"
#import "CLBUserSynchronizer.h"
#import "CLBErrorMessageOverlay.h"
#import "CLBCreateConversationButton.h"

@interface CLBConversationListViewController () <UITableViewDataSource, UITableViewDelegate, CLBErrorMessageOverlayDelegate>

@property (nonatomic) CLBConversationListViewModel *viewModel;
@property (nonatomic) UIStatusBarStyle statusBarStyle;
@property (nonatomic) UIStatusBarStyle appStatusBarStyle;

@property (nonatomic, weak) CLBEmptyListView *emptyListView;
@property (nonatomic, weak) CLBCreateConversationButton *conversationButton;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) CLBErrorMessageOverlay *errorMessageOverlay;

@end

@implementation CLBConversationListViewController

static BOOL _isConversationListShown = NO;

+ (BOOL)isConversationListShown {
    return _isConversationListShown;
}

- (CLBErrorMessageOverlay *)errorMessageOverlay {
    if (!_errorMessageOverlay) {
        [self initErrorMessageOverlay];
    }
    return _errorMessageOverlay;
}

- (instancetype)initWithDeps:(CLBDependencyManager *)deps utilitySettings:(id<CLBUtilitySettings>)utilitySettings showCreateConversationButton:(BOOL)showCreateConversationButton {
    self = [super init];
    if (self) {
        _viewModel = [[CLBConversationListViewModel alloc] initWithAppName:deps.config.appName
                                                        appAvatarUrlString:deps.config.appIconUrlString
                                                          userSynchronizer:deps.userSynchronizer
                                                    conversationController:deps.conversationController
                                                           utilitySettings:utilitySettings
                                              showCreateConversationButton:showCreateConversationButton
                                            canUserCreateMoreConversations:deps.config.canUserCreateMoreConversations
                                                               accentColor:deps.sdkSettings.conversationListAccentColor];
        _statusBarStyle = CLBConversationStatusBarStyle();
        _appStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    }
    return self;
}

- (void)conversationDidLoad:(NSString *)conversationId conversationController:(CLBConversationController *)conversationController {
    [self.viewModel
     setConversationController:conversationController
     shouldSubscribeForDataChanges:CLBConversationListViewController.isConversationListShown];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.navigationController) {
        [NSException raise:@"NavigationControllerNotFound" format:@"Conversations screen must be embedded in a navigation controller"];
    }

    [self setupViewModel];

    self.view.backgroundColor = CLBSystemBackgroundColor();
    [self initNavBarWithTitle:self.viewModel.navigationTitle closeButtonTitle:self.viewModel.closeButtonTitle];
    [self initTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.viewModel subscribeForDataChanges];
    [self.viewModel getConversations];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _isConversationListShown = YES;
    [self.viewModel startMonitoringNetwork];
    [self handleStatusBarStyle];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self handleStatusBarStyle];
    [self.viewModel unsubscribeForDataChanges];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    _isConversationListShown = NO;
    [self.viewModel stopMonitoringNetwork];
}

- (void)setupViewModel {
    __weak CLBConversationListViewController *weakSelf = self;
    self.viewModel.isEmptyChangedBlock = ^void() {
        if (!weakSelf) return;
        if (weakSelf.viewModel.isEmpty) {
            if (!weakSelf.emptyListView) {
                [weakSelf showEmptyScreenWithText:weakSelf.viewModel.emptyViewText];
                weakSelf.tableView.hidden = YES;
            }
        } else {
            [weakSelf.emptyListView removeFromSuperview];
            weakSelf.tableView.hidden = NO;
        }
    };
    self.viewModel.conversationsChangedBlock = ^void() {
        if (!weakSelf) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    };
    self.viewModel.hasErrorChangedBlock = ^{
        if (!weakSelf) return;
        if (weakSelf.viewModel.hasError) {
            UIButton *retryButton;
            if (weakSelf.viewModel.errorRetryAction) {
                retryButton = [UIButton new];
                [retryButton setTitle:[CLBLocalization localizedStringForKey:@"Retry"] forState:UIControlStateNormal];
                [retryButton addTarget:weakSelf.viewModel action:weakSelf.viewModel.errorRetryAction forControlEvents:UIControlEventTouchUpInside];
            }
            [weakSelf.errorMessageOverlay showWithText:weakSelf.viewModel.errorMessage button:retryButton animated:YES];
        } else {
            [weakSelf.errorMessageOverlay hideAnimated:YES];
        }
    };
    self.viewModel.isCreateConversationButtonEnabledChangedBlock = ^void(){
        if (!weakSelf) return;
        if (weakSelf.viewModel.isCreateConversationButtonEnabled) {
            weakSelf.conversationButton.enabled = YES;
        } else {
            weakSelf.conversationButton.enabled = NO;
        }
    };
    self.viewModel.shouldShowCreateConversationButtonChangedBlock = ^void(){
        if (!weakSelf) return;
        if (weakSelf.viewModel.shouldShowCreateConversationButton) {
            [weakSelf addCreateConversationView];
        } else {
            [weakSelf removeCreateConversationView];
        }
    };
    self.viewModel.hasLoadMoreIndicatorChangedBlock = ^{
        if (!weakSelf) return;
        if (weakSelf.viewModel.hasLoadMoreIndicator) {
            [weakSelf showLoadMoreIndicator];
        } else {
            [weakSelf hideLoadMoreIndicator];
        }
    };
}

- (void)initNavBarWithTitle:(NSString *)title closeButtonTitle:(NSString *)closeButtonTitle {
    self.navigationItem.title = title;
    
    // workaround to remove dropshadow under navBar
    self.navigationController.navigationBar.backgroundColor = CLBSystemBackgroundColor();
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.tintColor = CLBNavBarItemTextColor();
    
    if(self.isBeingPresented || self.navigationController.isBeingPresented) {
        if (@available(iOS 13.0, *)) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(close)];
        } else {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:closeButtonTitle style:UIBarButtonItemStylePlain target:self action:@selector(close)];
        }
    }
    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = YES;
    }
}

- (void)close {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)showEmptyScreenWithText:(NSString *)text {
    CLBEmptyListView *emptyListView = [[CLBEmptyListView alloc] initWithText:text];
    self.emptyListView = emptyListView;
    [self.view addSubview:self.emptyListView];

    self.emptyListView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.emptyListView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.emptyListView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.emptyListView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.emptyListView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
}

- (void)initTableView {
    UITableView *tableView = [[UITableView alloc] init];
    self.tableView = tableView;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.view addSubview:self.tableView];

    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    if (@available(iOS 11.0, *)) {
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor].active = YES;
    } else {
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    }
    [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:CLBConversationListTableViewCell.class forCellReuseIdentifier:CLBConversationListTableViewCell.cellIdentifier];
}

- (void)initErrorMessageOverlay {
    CLBErrorMessageOverlay *errorMessageOverlay = [[CLBErrorMessageOverlay alloc] initWithConstraints];
    self.errorMessageOverlay = errorMessageOverlay;
    [self.view addSubview:self.errorMessageOverlay];

    self.errorMessageOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *topConstraint;
    if (@available(iOS 11.0, *)) {
        topConstraint = [self.errorMessageOverlay.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor];
    } else {
        topConstraint = [self.errorMessageOverlay.topAnchor constraintEqualToAnchor:self.view.topAnchor];
    }
    [NSLayoutConstraint activateConstraints:@[topConstraint,
                                              [self.errorMessageOverlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
                                              [self.errorMessageOverlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]]];

    self.errorMessageOverlay.delegate = self;
}

- (void)handleStatusBarStyle {
    if ((self.isBeingPresented || self.isMovingToParentViewController)) {
        [UIApplication sharedApplication].statusBarStyle = self.statusBarStyle;
    } else if (self.isBeingDismissed
               || self.isMovingFromParentViewController
               || self.navigationController.isBeingDismissed
               || self.navigationController.isMovingFromParentViewController) {
        [UIApplication sharedApplication].statusBarStyle = self.appStatusBarStyle;
    }
}

- (NSInteger)minScrollViewContentOffsetY {
    if (self.viewModel.hasError) {
        // Avoids the large title to bounce under the error view
        return -38;
    } else {
        return -NSIntegerMax;
    }
}

- (void)userInteractionEnabled:(BOOL)enabled {
    self.tableView.userInteractionEnabled = enabled;
    self.conversationButton.userInteractionEnabled = enabled;
}

- (void)showLoadMoreIndicator {
    UIView* footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
    UIActivityIndicatorView *spinner = [UIActivityIndicatorView new];
    spinner.center = footerView.center;
    [footerView addSubview:spinner];
    [spinner startAnimating];
    self.tableView.tableFooterView = footerView;
}

- (void)hideLoadMoreIndicator {
    self.tableView.tableFooterView = nil;
}

// MARK: UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel numberOfConversations];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CLBConversationListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CLBConversationListTableViewCell.cellIdentifier forIndexPath:indexPath];
    if (cell) {
        CLBConversationViewModel *viewModel = [self.viewModel conversationForIndexPath:indexPath];
        [cell configureWithConversationViewModel:viewModel];
    }
    return cell;
}

// MARK: UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self userInteractionEnabled:NO];
    
    __weak CLBConversationListViewController *weakSelf = self;
    [self.viewModel selectConversationForIndexPath:indexPath completionHandler:^{
        if (!weakSelf.viewModel.hasError) {
            [weakSelf.navigationController pushViewController:[ClarabridgeChat newConversationViewController] animated:YES];
        }
        [weakSelf.tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [weakSelf userInteractionEnabled:YES];
    }];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Required for iOS 10.
    return 76;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.viewModel shouldLoadMoreConversationsForNextIndexPath:indexPath]) {
        [self.viewModel loadMoreConversations];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat minContentOffsetY = self.minScrollViewContentOffsetY;
    if (scrollView.contentOffset.y < minContentOffsetY) {
        scrollView.contentOffset = CGPointMake(0, minContentOffsetY);
    }
}

// MARK: CLBErrorMessageOverlayDelegate

- (void)errorMessageOverlay:(CLBErrorMessageOverlay *)errorMessageOverlay changedWithIsHidden:(BOOL)isHidden animated:(BOOL)animated {
    UIEdgeInsets contentInset = self.tableView.contentInset;
    if (isHidden) {
        contentInset.top -= errorMessageOverlay.frame.size.height;
    } else {
        contentInset.top += errorMessageOverlay.frame.size.height;
    }

    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.tableView.contentInset = contentInset;
            if (self.tableView.contentOffset.y == 0) {
                CGPoint contentOffset = self.tableView.contentOffset;
                contentOffset.y = -contentInset.top;
                self.tableView.contentOffset = contentOffset;
            }
        }];
    } else {
        self.tableView.contentInset = contentInset;
    }
}

// MARK: Create Conversation

- (void)addCreateConversationView {

    if (!self.viewModel.shouldShowCreateConversationButton) {
        return;
    }

    if (self.conversationButton) {
        return;
    }

    CLBCreateConversationButton *conversationButton = [CLBCreateConversationButton createConversationButtonWithColor:self.viewModel.accentColor];

    self.conversationButton = conversationButton;

    [self.conversationButton addTarget:self action:@selector(createConversationButtonAction) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.conversationButton];
    [self.view bringSubviewToFront:self.conversationButton];

    if (@available(iOS 11.0, *)) {
        [self.conversationButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8].active = YES;
        [self.conversationButton.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:16].active = YES;
        [self.conversationButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-16].active = YES;
    } else {
        [self.conversationButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-8].active = YES;
        [self.conversationButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16].active = YES;
        [self.conversationButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16].active = YES;
    }

    // Update table view content inset to allow user to scroll table to see the last row
    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.bottom = kConversationButtonHeight;
    self.tableView.contentInset = contentInset;

}

- (void)removeCreateConversationView {

    if (!self.conversationButton) {
        return;
    }

    [self.conversationButton removeFromSuperview];
    self.conversationButton = nil;

    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.bottom = 0;
    self.tableView.contentInset = contentInset;
}

- (void)createConversationButtonAction {

    if ([self.delegate respondsToSelector:@selector(conversationListDidSelectCreateConversation)]) {

        CLBEnsureMainThread(^{
            [self.delegate conversationListDidSelectCreateConversation];
        });
    }

    if ([self.delegate respondsToSelector:@selector(shouldCreateCustomConversationFlow)] && [self.delegate shouldCreateCustomConversationFlow]) {
        return;
    } else {
        [self userInteractionEnabled:NO];

        __weak CLBConversationListViewController *weakSelf = self;
        [self.viewModel createConversationWithCompletionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {

            if (!error) {
                CLBEnsureMainThread(^{
                    [weakSelf.navigationController pushViewController:[ClarabridgeChat newConversationViewController] animated:YES];
                });
            }
            
            [weakSelf userInteractionEnabled:YES];
        }];
    }
}

@end
