//
//  CLBConversationSynchronizer.m
//  ClarabridgeChat
//
//  Created by Shona Nunez on 07/02/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBConversationSynchronizer.h"
#import "CLBRemoteObjectSynchronizer.h"
#import "CLBApiClient.h"
#import "CLBSettings+Private.h"
#import "CLBClientInfo.h"
#import "CLBUser.h"
#import "CLBUtilitySettings.h"

NSString *const CLBDataSessionTokenString = @"sessionToken";
NSString *const CLBDataUserIdString = @"appUserId";
NSString *const CLBDataExternalIdString = @"userId";
NSString *const CLBDataClientString = @"client";

@interface CLBConversationSynchronizer()

@property CLBRemoteObjectSynchronizer *synchronizer;
@property CLBSettings *settings;
@property CLBUser *user;
@property id<CLBUtilitySettings> utilitySettings;

@end

@implementation CLBConversationSynchronizer

- (instancetype)initWithUser:(CLBUser *)user
                synchronizer:(CLBRemoteObjectSynchronizer *)synchronizer
                    settings:(CLBSettings *)settings
             utilitySettings:(id<CLBUtilitySettings>)utilitySettings {
    self = [super init];

    if (self) {
        self.synchronizer = synchronizer;
        self.settings = settings;
        self.user = user;
    }

    return self;
}

- (void)getConversationById:(NSString *)conversationId withCompletionHandler:(void (^)(NSError * _Nullable, NSDictionary * _Nullable))handler {
    NSString *url = [NSString stringWithFormat:@"/v2/apps/%@/appusers/%@/conversations/%@", self.settings.appId, self.user.userId, conversationId];

    [self.synchronizer.apiClient GET:url
                          parameters:nil
                          completion:^(NSURLSessionDataTask * _Nullable task, NSError * _Nullable error, id  _Nullable responseObject) {
        if (handler) {
            handler(error, responseObject);
        }
    }];
}


- (void)getConversationListWithCompletionHandler:(void (^)(NSError * _Nullable, NSDictionary * _Nullable))handler {
    [self getConversationListWithOffset:0 completionHandler:handler];
}

- (void)getConversationListWithOffset:(NSUInteger)offset completionHandler:(void (^)(NSError * _Nullable, NSDictionary * _Nullable))handler {
    NSString *url = [NSString stringWithFormat:@"/v2/apps/%@/appusers/%@/conversations", self.settings.appId, self.user.userId];

    NSString *offsetString = [NSString stringWithFormat:@"%lu", (unsigned long)offset];

    [self.synchronizer.apiClient GET:url
                          parameters:@{@"offset": offsetString}
                          completion:^(NSURLSessionDataTask * _Nullable task, NSError * _Nullable error, id  _Nullable responseObject) {
        if (handler) {
            handler(error, responseObject);
        }
    }];
}

@end
