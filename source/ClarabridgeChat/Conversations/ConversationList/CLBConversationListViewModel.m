//
//  CLBConversationListViewModel.m
//  ClarabridgeChat
//
//  Created by Thaciana Lima on 25/05/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBConversationListViewModel.h"
#import "CLBLocalization.h"
#import "CLBUserSynchronizer.h"
#import "CLBConversationViewModel.h"
#import "CLBConversation+Mapper.h"
#import "CLBConfig.h"
#import "CLBParticipant.h"
#import "CLBConversationStorageManager.h"
#import "ClarabridgeChat+Private.h"
#import "CLBUtilitySettings.h"
#import "CLBConversationList.h"

#define CHECK_NULL_EXEC_BLOCK(BLOCK) if (BLOCK != nil) BLOCK()

@interface CLBConversationListViewModel ()

@property (nonatomic) BOOL empty;
@property (nonatomic) NSArray<CLBConversationViewModel *> *conversations;
@property (nonatomic) NSString *appName;
@property (nonatomic) NSString *appAvatarURLString;
@property (nonatomic) CLBUserSynchronizer *userSynchronizer;
@property (nonatomic, weak) CLBConversationController *conversationController;
@property (nonatomic) BOOL error;
@property (nonatomic) NSString *errorMessage;
@property (nonatomic) SEL errorRetryAction;
@property (nonatomic) id<CLBUtilitySettings> utilitySettings;
@property (nonatomic) BOOL isLoadingConversation;
@property (nonatomic) BOOL showCreateConversationButton;
@property (nonatomic) BOOL canUserCreateMoreConversations;
@property (nonatomic) BOOL hasMore;
@property (nonatomic) BOOL isLoadindMoreConversations;

@end

@implementation CLBConversationListViewModel

- (void)setEmpty:(BOOL)empty {
    _empty = empty;
    dispatch_async(dispatch_get_main_queue(), ^{
       CHECK_NULL_EXEC_BLOCK(self.isEmptyChangedBlock);
    });
}

-(void)setConversations:(NSArray<CLBConversationViewModel *> *)conversations {
    _conversations = conversations;
    dispatch_async(dispatch_get_main_queue(), ^{
        CHECK_NULL_EXEC_BLOCK(self.conversationsChangedBlock);
    });
}

- (void)setError:(BOOL)error {
    _error = error;
    dispatch_async(dispatch_get_main_queue(), ^{
        CHECK_NULL_EXEC_BLOCK(self.hasErrorChangedBlock);
    });
}

- (void)setLoadMoreIndicator:(BOOL)loadMoreIndicator {
    if (_loadMoreIndicator != loadMoreIndicator) {
        _loadMoreIndicator = loadMoreIndicator;
        dispatch_async(dispatch_get_main_queue(), ^{
            CHECK_NULL_EXEC_BLOCK(self.hasLoadMoreIndicatorChangedBlock);
        });
    }
}

- (void)setIsLoadindMoreConversations:(BOOL)isPaginating {
    _isLoadindMoreConversations = isPaginating;
    self.loadMoreIndicator = self.isLoadindMoreConversations;
}

- (instancetype)initWithAppName:(NSString *)appName
             appAvatarUrlString:(NSString *)appAvatarUrlString
               userSynchronizer:(id<CLBUserSynchronizerProtocol>)userSynchronizer
         conversationController:(nullable CLBConversationController *)conversationController
                utilitySettings:(id<CLBUtilitySettings>)utilitySetting
   showCreateConversationButton:(BOOL) showCreateConversationButton
 canUserCreateMoreConversations:(BOOL) canUserCreateMoreConversations
                    accentColor:(UIColor *)accentColor {
    self = [super init];
    if (self) {
         _empty = YES;
        _appName = appName;
        _appAvatarURLString = appAvatarUrlString;
        _navigationTitle = [CLBLocalization localizedStringForKey:@"My Conversations"];
        _emptyViewText = [CLBLocalization localizedStringForKey:@"No conversations"];
        _closeButtonTitle = [CLBLocalization localizedStringForKey:@"Done"];
        _userSynchronizer = userSynchronizer;
        _conversationController = conversationController;
        _utilitySettings = utilitySetting;
        _showCreateConversationButton = showCreateConversationButton;
        _canUserCreateMoreConversations = canUserCreateMoreConversations;
        _accentColor = accentColor;
        _hasMore = NO;
        _isLoadindMoreConversations = NO;
        _loadMoreIndicator = NO;
    }
    return self;
}

- (void)getConversations {
    __weak CLBConversationListViewModel *weakSelf = self;
    [self.userSynchronizer loadConversationListWithCompletionHandler:^(NSError * _Nullable error, CLBConversationList * _Nullable conversationList) {
        if (conversationList.conversations.count > 0) {
            weakSelf.empty = NO;

            weakSelf.conversations = [weakSelf conversationViewModelsForConversations:conversationList.conversations users:conversationList.users];
            weakSelf.hasMore = conversationList.hasMore;
            dispatch_async(dispatch_get_main_queue(), ^{
                CHECK_NULL_EXEC_BLOCK(self.shouldShowCreateConversationButtonChangedBlock);
            });
        } else {
            weakSelf.empty = YES;

            weakSelf.hasMore = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                CHECK_NULL_EXEC_BLOCK(self.shouldShowCreateConversationButtonChangedBlock);
            });
        }
    }];
}

- (void)subscribeForDataChanges {
    if (!self.conversationController) {
        return;
    }

    __weak CLBConversationListViewModel *weakSelf = self;
    weakSelf.conversationController.reloadConversationList = ^void() {
        if (!weakSelf) return;
        [weakSelf getConversations];
    };
}

- (void)unsubscribeForDataChanges {
    if (!self.conversationController) {
        return;
    }

    self.conversationController.reloadConversationList = nil;
}

- (NSUInteger)numberOfConversations {
    return self.conversations.count;
}

- (CLBConversationViewModel *)conversationForIndexPath:(NSIndexPath *)indexPath {
    return self.conversations[indexPath.row];
}

- (void)selectConversationForIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^_Nonnull)(void))completionHandler {
    if (!self.utilitySettings.isNetworkAvailable
        || self.isLoadingConversation) {
        CHECK_NULL_EXEC_BLOCK(completionHandler);
        return;
    }

    self.error = NO;

    CLBConversationViewModel *selectedConversation = [self conversationForIndexPath:indexPath];
    CLBConversation *previouslyLoadedConversation = self.userSynchronizer.conversation;
    if ([previouslyLoadedConversation.conversationId isEqualToString:selectedConversation.conversationId]) {
        CHECK_NULL_EXEC_BLOCK(completionHandler);
        return;
    }

    self.isLoadingConversation = YES;

    __weak CLBConversationListViewModel *weakSelf = self;
    [self.userSynchronizer loadConversation:selectedConversation.conversationId completionHandler:^(NSError * error, NSDictionary * userInfo) {
        if (error) {
            NSLog(@"<CLARABRIDGECHAT::ERROR> failed to load conversation: %@", selectedConversation.conversationId);
            weakSelf.errorMessage = [CLBLocalization localizedStringForKey:@"Failed to load conversation"];
            weakSelf.errorRetryAction = nil;
            weakSelf.error = YES;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            CHECK_NULL_EXEC_BLOCK(completionHandler);
        });
        weakSelf.isLoadingConversation = NO;
    }];
}

- (void)startMonitoringNetwork {
    [self verifyIsNetworkAvailable];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(verifyIsNetworkAvailable)
                                                 name:CLBReachabilityStatusChangedNotification object:nil];
}

- (void)stopMonitoringNetwork {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CLBReachabilityStatusChangedNotification object:nil];
}

- (void)setConversationController:(CLBConversationController *)conversationController shouldSubscribeForDataChanges:(BOOL)shouldSubscribeForDataChanges {
    self.conversationController = conversationController;
    if (shouldSubscribeForDataChanges) {
        [self subscribeForDataChanges];
    }
}

- (BOOL)shouldLoadMoreConversationsForNextIndexPath:(NSIndexPath *)nextIndexPath {
    if (!(self.conversations.count > 0)) {
        return false;
    }
    
    BOOL hasReachedPreloadOffset = nextIndexPath.row + 4 > self.conversations.count;
    return hasReachedPreloadOffset;
}

- (void)loadMoreConversations {
    if (!self.utilitySettings.isNetworkAvailable
        || self.isLoadindMoreConversations
        || !self.hasMore) {
        return;
    }

    self.error = NO;
    self.isLoadindMoreConversations = YES;

    __weak CLBConversationListViewModel *weakSelf = self;
    [self.conversationController getMoreConversations:^(NSError * error) {
        if (error) {
            NSLog(@"<CLARABRIDGECHAT::ERROR> Unable to load conversations");
            self.errorMessage = [CLBLocalization localizedStringForKey:@"Unable to load conversations"];
            self.errorRetryAction = @selector(loadMoreConversations);
            self.error = YES;
        }
        weakSelf.isLoadindMoreConversations = NO;
    }];
}

// MARK: Private methods

- (NSArray<CLBConversationViewModel *> *)conversationViewModelsForConversations:(NSArray<CLBConversation *> *)conversations users:(NSArray<CLBUser *> *)users {
    NSMutableArray<CLBConversationViewModel *> *conversationViewModels = [[NSMutableArray alloc] initWithCapacity:conversations.count];
    for (CLBConversation *conversation in conversations) {
        [conversationViewModels addObject:[conversation conversationViewModelWithAppAvatarURLString:self.appAvatarURLString appName:self.appName users:users]];
    }

    return [conversationViewModels copy];
}

- (void)verifyIsNetworkAvailable {
    if (self.utilitySettings.isNetworkAvailable) {
        self.error = NO;
        _createConversationButtonEnabled = YES;
    } else {
        self.errorMessage = [CLBLocalization localizedStringForKey:@"No Internet connection"];
        self.errorRetryAction = nil;
        self.error = YES;
        _createConversationButtonEnabled = NO;
    }
}

/*
  * Given a ViewModel instance
  * With     <-   `showCreateConversationButton` -> Integrator Mobile SDK Settings
  * And      <- `canUserCreateMoreConversations` -> API Webservice Backend Settings
  * And      <-        `hasConversations`        -> Indicates if the conversation list is empty or not
  * When this method is called
  * Then the return value will be VISIBILITY
  * |:---:|:------------------------------:|:---------------:|:-----------------------------:|:----------:|
  * | No. | canUserCreateMoreConversations | hasConversations | showCreateConversationButton | VISIBILITY |
  * |:---:|:------------------------------:|:---------------:|:-----------------------------:|:----------:|
  * |  1  |              True              |      True       |           True                |    SHOW    |
  * |  2  |              True              |      True       |           False               |    HIDE    |
  * |  3  |              True              |      False      |           True                |    SHOW    |
  * |  4  |              True              |      False      |           False               |    HIDE    |
  * |  5  |              False             |      True       |           True                |    HIDE    |
  * |  6  |              False             |      True       |           False               |    HIDE    |
  * |  7  |              False             |      False      |           True                |    SHOW    |
  * |  8  |              False             |      False      |           False               |    HIDE    |
  * |:---:|:------------------------------:|:---------------:|:-----------------------------:|:----------:|
 */
- (BOOL)shouldShowCreateConversationButton {
    if (self.canUserCreateMoreConversations) {
        return self.showCreateConversationButton;
    } else {
        return (!self.hasConversations && self.showCreateConversationButton);
    }
}

- (BOOL)hasConversations {
    return self.conversations.count > 0;
}

- (void)createConversationWithCompletionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler {
    if (!self.utilitySettings.isNetworkAvailable) {
        if (completionHandler) {
            completionHandler(NSError.new, nil);
        }
        return;
    }

    self.error = NO;

    __weak CLBConversationListViewModel *weakSelf = self;
    [self.userSynchronizer createConversationOrUserWithName:nil description:nil iconUrl:nil avatarUrl:nil metadata:nil messages:nil intent:@"conversation:start" completionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
            if (error) {
                NSLog(@"<CLARABRIDGECHAT::ERROR> failed to create conversation");
                weakSelf.errorMessage = [CLBLocalization localizedStringForKey:@"Failed to create conversation"];
                weakSelf.errorRetryAction = nil;
                weakSelf.error = YES;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandler) {
                    completionHandler(error, userInfo);
                }
            });
    }];
}

@end
