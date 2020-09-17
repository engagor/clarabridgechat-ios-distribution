//
//  CLBConfigFetchScheduler.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBRemoteOperationScheduler.h"
#import "CLBUserSynchronizer.h"
#import "CLBConfigFetchSchedulerDelegate.h"

@class CLBConfig;

@interface CLBConfigFetchScheduler : CLBRemoteOperationScheduler

typedef void (^FetchCompletionHandler)(NSError *, NSDictionary *);

- (instancetype)initWithConfig:(CLBConfig *)config synchronizer:(CLBRemoteObjectSynchronizer *)synchronizer;

- (void)logPushTokenIfExists;
- (void)scheduleImmediatelyWithCompletion:(void(^)(NSError *error, NSDictionary *userInfo))handler;
- (void)addCallbackOnInitializationComplete:(void (^)(void))callback;

@property(readonly) CLBConfig *config;
@property BOOL isInitializationComplete;
@property FetchCompletionHandler fetchCompletionHandler;
@property NSMutableArray *callbacksOnInitComplete;
@property (weak) id<CLBConfigFetchSchedulerDelegate> delegate;



@end
