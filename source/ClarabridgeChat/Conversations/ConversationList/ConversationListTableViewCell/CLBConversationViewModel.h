//
//  CLBConversationViewModel.h
//  ClarabridgeChat
//
//  Created by Conor Nolan on 20/05/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CLBImageLoader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CLBConversationViewModel : NSObject

@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *conversationId;
@property (nonatomic, readonly) NSString *formattedLastUpdated;
@property (nonatomic, readonly) NSString *formattedUnreadCount;
@property (nonatomic, readonly) NSString *lastMessage;
@property (nonatomic, readonly) NSString *avatarURLString;
@property (nonatomic, readonly) NSUInteger unreadCount;
@property (nonatomic, readonly) CLBImageLoader *imageLoader;

@property (nonatomic, copy, nullable) void (^avatarChangedBlock)(UIImage *image);
@property (nonatomic, copy, nullable) void (^formattedLastUpdatedChangedBlock)(void);

- (instancetype)initWithDisplayName:(nullable NSString *)displayName
                  andConversationId:(NSString *)conversationId
                     andLastUpdated:(nullable NSDate *)lastUpdated
                     andLastMessage:(nullable NSString *)lastMessage
                 andAvatarURLString:(nullable NSString *)avatar
                     andUnreadCount:(NSUInteger)unreadCount
                         andAppName:(nullable NSString *)appName;

- (void)loadAvatarWithImageLoader:(CLBImageLoader *)imageLoader;
- (void)startTemporalUpdates;
- (void)stopTemporalUpdates;

@end

NS_ASSUME_NONNULL_END
