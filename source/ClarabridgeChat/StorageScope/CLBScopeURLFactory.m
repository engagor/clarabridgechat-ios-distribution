//
//  CLBScopeURLFactory.m
//  ClarabridgeChat
//
//  Created by Alan Egan on 25/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import "CLBScopeURLFactory.h"
#import "CLBClarabridgeChatScopeURLProvider.h"

@interface CLBScopeURLFactory ()

@property (nonatomic, strong, readonly) NSString *unscopedPath;
@property (nonatomic, strong, readonly) NSString *integrationScopePath;
@property (nonatomic, strong, readonly) NSString *appScopePath;
@property (nonatomic, strong, readonly) NSString *userScopePath;

@property (nonatomic, strong) NSMutableDictionary<NSString *, CLBClarabridgeChatScopeURLProvider *> *providers;

@end

@implementation CLBScopeURLFactory

- (id<CLBScopeURLProvider>)urlProviderFor:(CLBStorageScope)scope {
    CLBClarabridgeChatScopeURLProvider *urlProvider;

    switch (scope) {
        case CLBStorageScopeIntegration:
            urlProvider = [self providerForScopePath:self.integrationScopePath];
            break;
        case CLBStorageScopeApp:
            urlProvider = [self providerForScopePath:self.appScopePath];
            break;
        case CLBStorageScopeUser:
            urlProvider = [self providerForScopePath:self.userScopePath];
            break;
        default:
            urlProvider = [self providerForScopePath:self.unscopedPath];
            break;
    }

    return urlProvider;
}

- (NSString *)unscopedPath {
    return @"general";
}

- (NSString *)integrationScopePath {
    return @"integration";
}

- (NSString *)appScopePath {
    return @"app";
}

- (NSString *)userScopePath {
    return @"user";
}

- (CLBClarabridgeChatScopeURLProvider *)providerForScopePath:(NSString *)scopePath {
    CLBClarabridgeChatScopeURLProvider *provider = self.providers[scopePath];

    if (!provider) {
        provider = [[CLBClarabridgeChatScopeURLProvider alloc] initWithScopePath:scopePath];
        self.providers[scopePath] = provider;
    }

    return provider;
}

@end
