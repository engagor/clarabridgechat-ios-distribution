//
//  CLBConversationViewModel.m
//  ClarabridgeChat
//
//  Created by Conor Nolan on 20/05/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBUtility.h"
#import "CLBConversationViewModel.h"
#import "ClarabridgeChat+Private.h"
#import "CLBLocalization.h"
#import "NSDate+Helper.h"

@interface CLBConversationViewModel ()

@property (nonatomic) NSDate *lastUpdated;
@property (nonatomic) NSTimer *timer;

@end

@implementation CLBConversationViewModel : NSObject

- (NSString *)formattedLastUpdated {
    return self.lastUpdated ? [self.lastUpdated relativeDateAsString] : @"";
}

- (instancetype)initWithDisplayName:(NSString *)displayName
                  andConversationId:(nonnull NSString *)conversationId
                     andLastUpdated:(NSDate *)lastUpdated
                     andLastMessage:(NSString *)lastMessage
                          andAvatarURLString:(NSString *)avatarURLString
                     andUnreadCount:(NSUInteger)unreadCount
                         andAppName:(NSString *)appName {
    
    self = [super init];
    if (!self) return nil;

    _displayName = displayName;
    _conversationId = conversationId;
    _lastUpdated = lastUpdated;
    _avatarURLString = avatarURLString;
    _lastMessage = lastMessage ? lastMessage : @"";
    _unreadCount = unreadCount;
    _imageLoader = [ClarabridgeChat avatarImageLoader];
    _formattedUnreadCount = unreadCount < 9 ? [NSString stringWithFormat:@"%lu", (unsigned long)unreadCount] : [CLBLocalization localizedStringForKey:@"9+"];

    return self;
}

- (void)dealloc {
    [self stopTemporalUpdates];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    }

    if (![other isKindOfClass:[CLBConversationViewModel class]]) {
        return NO;
    }

    return [self isEqualToConversationViewModel:other];
}

- (NSUInteger)hash
{
    return [self.displayName hash] ^
    [self.formattedLastUpdated hash] ^
    [self.formattedUnreadCount hash] ^
    [self.lastMessage hash] ^
    [self.avatarURLString hash] ^
    self.unreadCount;
}

- (BOOL)isEqualToConversationViewModel:(CLBConversationViewModel *)other {
    return [self.displayName isEqualToString:other.displayName] &&
    [self.formattedLastUpdated isEqualToString:other.formattedLastUpdated] &&
    [self.formattedUnreadCount isEqualToString:other.formattedUnreadCount] &&
    [self.lastMessage isEqualToString:other.lastMessage] &&
    self.unreadCount == other.unreadCount &&
    [self.avatarURLString isEqualToString:other.avatarURLString];
}

- (void)loadAvatarWithImageLoader:(CLBImageLoader *)imageLoader {
    if (!self.avatarURLString || self.avatarURLString.length == 0) return;

    UIImage* cachedImage = [imageLoader cachedImageForUrl:self.avatarURLString];
    if (cachedImage) {
        self.avatarChangedBlock(cachedImage);
    } else {
        __weak CLBConversationViewModel *weakSelf = self;
        [imageLoader loadImageForUrl:self.avatarURLString withCompletion:^(UIImage* image) {
            if (image && weakSelf.avatarChangedBlock) weakSelf.avatarChangedBlock(image);
        }];
    }

}

- (void)startTemporalUpdates {
    __weak CLBConversationViewModel *weakSelf = self;
    NSTimeInterval interval = 1*(60);
    self.timer = [NSTimer scheduledTimerWithTimeInterval:interval repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (!weakSelf) return;
        weakSelf.formattedLastUpdatedChangedBlock();
    }];
}

- (void)stopTemporalUpdates {
    [self.timer invalidate];
}

@end
