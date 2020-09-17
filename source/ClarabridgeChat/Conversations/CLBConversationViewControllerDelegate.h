//
//  CLBConversationViewControllerDelegate.h
//  ClarabridgeChat
//
//  Created by Shona Nunez on 20/11/2019.
//  Copyright © 2019 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLBMessage, CLBMessageAction, CLBConversationViewController, CLBConversation;

NS_ASSUME_NONNULL_BEGIN

@protocol CLBConversationViewControllerDelegate <NSObject>

- (void)conversationViewController:(CLBConversationViewController *)controller didBeginTypingInConversation:(NSString *)conversationId;
- (void)conversationViewController:(CLBConversationViewController *)controller didFinishTypingInConversation:(NSString *)conversationId;
- (void)conversationViewController:(CLBConversationViewController *)controller didMarkAllAsReadInConversation:(NSString *)conversationId;

- (BOOL)conversationViewController:(CLBConversationViewController *)controller shouldLoadPreviousMessagesInConversation:(NSString *)conversationId;
- (void)conversationViewController:(CLBConversationViewController *)controller didLoadPreviousMessagesInConversation:(NSString *)conversationId;
- (void)conversationViewController:(CLBConversationViewController *)controller didRetryMessage:(CLBMessage *)message inConversation:(NSString *)conversationId;

- (BOOL)conversationViewControllerCanCheckIsAppValid:(CLBConversationViewController *)controller;
- (BOOL)conversationViewControllerShouldWorkOffline:(CLBConversationViewController *)controller;
- (BOOL)conversationViewControllerCanSendMessage:(CLBConversationViewController *)controller;
- (BOOL)conversationViewController:(CLBConversationViewController *)controller canSendMessage:(NSString *)messageText;

- (void)conversationViewController:(CLBConversationViewController *)controller didSendMessage:(CLBMessage *)message inConversation:(NSString *)conversationId;
- (void)conversationViewController:(CLBConversationViewController *)controller didSendMessageText:(NSString *)text inConversation:(NSString *)conversationId;
- (void)conversationViewController:(CLBConversationViewController *)controller didSendMessageFromAction:(CLBMessageAction *)action inConversation:(NSString *)conversationId;

- (void)conversationViewController:(CLBConversationViewController *)controller didSendImage:(UIImage *)image inConversation:(NSString *)conversationId;
- (void)conversationViewController:(CLBConversationViewController *)controller didSendFileURL:(NSURL *)fileLocation inConversation:(NSString *)conversationId;
- (NSString * _Nullable)conversationViewController:(CLBConversationViewController *)controller didCheckForErrorForFileURL:(NSURL *)fileLocation inConversation:(NSString *)conversationId;
- (void)conversationViewController:(CLBConversationViewController *)controller didSendPostback:(CLBMessageAction *)action inConversation:(NSString *)conversationId completion:(void (^)(NSError * _Nullable error))completion;
- (BOOL)isPushEnabled;
- (CLBConversation*)conversation:(NSString*)conversationId;

@end

NS_ASSUME_NONNULL_END
