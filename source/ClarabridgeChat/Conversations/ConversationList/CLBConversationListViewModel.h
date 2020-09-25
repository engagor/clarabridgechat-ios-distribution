//
//  CLBConversationListViewModel.h
//  ClarabridgeChat
//
//  Created by Thaciana Lima on 25/05/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBConversationController.h"

@class CLBConversationViewModel;
@protocol CLBUserSynchronizerProtocol, CLBUtilitySettings;

NS_ASSUME_NONNULL_BEGIN

@interface CLBConversationListViewModel : NSObject

@property (nonatomic, readonly) NSString *navigationTitle;
@property (nonatomic, readonly) NSString *closeButtonTitle;
@property (nonatomic, readonly, getter=isEmpty) BOOL empty;
@property (nonatomic, readonly) NSString *emptyViewText;
@property (nonatomic, readonly, getter=isCreateConversationButtonEnabled) BOOL createConversationButtonEnabled;
@property (nonatomic, readonly, getter=hasError) BOOL error;
@property (nonatomic, readonly, nullable) NSString *errorMessage;
@property (nonatomic, readonly, nullable) SEL errorRetryAction;
@property (nonatomic, readonly, getter=hasLoadMoreIndicator) BOOL loadMoreIndicator;

@property (nonatomic, copy, nullable) void (^isEmptyChangedBlock)(void);
@property (nonatomic, copy, nullable) void (^conversationsChangedBlock)(void);
@property (nonatomic, copy, nullable) void (^isCreateConversationButtonEnabledChangedBlock)(void);
@property (nonatomic, copy, nullable) void (^shouldShowCreateConversationButtonChangedBlock)(void);
@property (nonatomic, copy, nullable) void (^hasErrorChangedBlock)(void);
@property (nonatomic, copy, nullable) void (^hasLoadMoreIndicatorChangedBlock)(void);

@property (nonatomic) UIColor *accentColor;

- (instancetype)initWithAppName:(NSString *)appName
            appAvatarUrlString:(NSString *)appAvatarUrlString
              userSynchronizer:(id<CLBUserSynchronizerProtocol>)userSynchronizer
        conversationController:(nullable CLBConversationController *)conversationController
               utilitySettings:(id<CLBUtilitySettings>)utilitySetting
  showCreateConversationButton:(BOOL) showCreateConversationButton
canUserCreateMoreConversations:(BOOL) canUserCreateMoreConversations
                  accentColor:(UIColor *)accentColor;

- (void)subscribeForDataChanges;
- (void)unsubscribeForDataChanges;
- (NSUInteger)numberOfConversations;
- (nullable CLBConversationViewModel *)conversationForIndexPath:(NSIndexPath *)indexPath;
- (void)selectConversationForIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^_Nonnull)(void))completionHandler;
- (void)startMonitoringNetwork;
- (void)stopMonitoringNetwork;
- (BOOL)shouldShowCreateConversationButton;
- (void)createConversationWithCompletionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler;
- (void)setConversationController:(CLBConversationController *)conversationController;
- (void)setConversationController:(CLBConversationController *)conversationController shouldSubscribeForDataChanges:(BOOL)shouldSubscribeForDataChanges;
- (void)getConversations;
- (BOOL)shouldLoadMoreConversationsForNextIndexPath:(NSIndexPath *)indexPath;
- (void)loadMoreConversations;

@end

NS_ASSUME_NONNULL_END
