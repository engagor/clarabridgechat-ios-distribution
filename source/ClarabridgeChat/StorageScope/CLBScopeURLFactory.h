//
//  CLBScopeURLFactory.h
//  ClarabridgeChat
//
//  Created by Alan Egan on 25/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBScopeURLProvider.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CLBStorageScope) {
    CLBStorageScopeUnscoped,
    CLBStorageScopeIntegration,
    CLBStorageScopeApp,
    CLBStorageScopeUser
};

CLB_FINAL_CLASS
@interface CLBScopeURLFactory : NSObject

- (id<CLBScopeURLProvider>)urlProviderFor:(CLBStorageScope)scope;

@end

NS_ASSUME_NONNULL_END
