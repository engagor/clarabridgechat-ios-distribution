//
//  CLBConversationSynchronizer.h
//  ClarabridgeChat
//
//  Created by Shona Nunez on 07/02/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBRemoteOperationScheduler.h"

@class CLBRemoteObjectSynchronizer, CLBSettings, CLBUser;
@protocol CLBUtilitySettings;

NS_ASSUME_NONNULL_BEGIN

@interface CLBConversationSynchronizer : NSObject

- (instancetype)initWithUser:(CLBUser *)user
                synchronizer:(CLBRemoteObjectSynchronizer *)synchronizer
                    settings:(CLBSettings *)settings
             utilitySettings:(id<CLBUtilitySettings>)utilitySettings;

- (void)getConversationListWithCompletionHandler:(void (^)(NSError * _Nullable, NSDictionary * _Nullable))handler;

- (void)getConversationListWithOffset:(NSUInteger)offset completionHandler:(void (^)(NSError * _Nullable, NSDictionary * _Nullable))handler;
- (void)getConversationById:(NSString *)conversationId withCompletionHandler:(void (^)(NSError * _Nullable, NSDictionary * _Nullable))handler;
@end

NS_ASSUME_NONNULL_END
