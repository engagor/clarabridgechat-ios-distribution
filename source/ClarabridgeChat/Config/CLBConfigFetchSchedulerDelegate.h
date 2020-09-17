//
//  CLBConffigFetchSchedulerDelegate.h
//  ClarabridgeChat
//
//  Created by Alan O'Connor on 21/02/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLBConfigFetchScheduler;

NS_ASSUME_NONNULL_BEGIN

@protocol CLBConfigFetchSchedulerDelegate <NSObject>
- (void)configFetchScheduler:(CLBConfigFetchScheduler *)scheduler didUpdateAppId:(NSString *)appId;
@end

NS_ASSUME_NONNULL_END
