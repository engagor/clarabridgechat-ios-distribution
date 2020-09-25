//
//  CLBUserSynchronizerProtocol.h
//  ClarabridgeChat
//
//  Created by Thaciana Lima on 08/06/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLBConversation;
@class CLBMessage;
@class CLBConversationList;

@protocol CLBUserSynchronizerProtocol <NSObject>
@property (nonatomic) CLBConversation *conversation;
- (void)loadConversations:(void (^ _Nullable)(NSError * _Nullable, NSArray *)) handler;
- (void)loadConversationListWithCompletionHandler: (void (^_Nullable)(NSError * _Nullable, CLBConversationList * _Nullable)) handler;
- (void)loadConversation:(NSString*)conversationId completionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler;
- (void)createConversationOrUserWithName:(nullable NSString *)name description:(nullable NSString *)description iconUrl:(nullable NSString *)iconUrl metadata:(nullable NSDictionary *)metadata messages:(nullable NSArray<CLBMessage *> *)messages intent:(nullable NSString *)intent completionHandler:(nullable void(^)(NSError * _Nullable error, NSDictionary * _Nullable userInfo))completionHandler;
@end

NS_ASSUME_NONNULL_END
