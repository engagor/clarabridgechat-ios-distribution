//
//  CLBRemoteOperationScheduler.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CLBRemoteObjectSynchronizer;
@class CLBRemoteResponse;
@protocol CLBRemoteObject;

typedef NS_ENUM(NSUInteger, CLBRemoteOperationSchedulerType) {
    CLBRemoteOperationSchedulerTypeFetch,
    CLBRemoteOperationSchedulerTypeSynchronize
};

extern NSString* const CLBRemoteOperationSchedulerStartedNotification;
extern NSString* const CLBRemoteOperationSchedulerCompletedNotification;

@interface CLBRemoteOperationScheduler : NSObject

-(instancetype)initWithRemoteObject:(id<CLBRemoteObject>)object synchronizer:(CLBRemoteObjectSynchronizer*)synchronizer;

-(void)execute;
-(void)scheduleImmediately;
-(void)scheduleAfter:(NSUInteger)seconds;

-(void)restore;
-(void)destroy;

-(void)addCallbackOnNextFetch:(void (^)(CLBRemoteResponse* response))callback;

@property id<CLBRemoteObject> remoteObject;
@property CLBRemoteObjectSynchronizer* synchronizer;
@property BOOL isExecuting;
@property CLBRemoteOperationSchedulerType type;
@property NSUInteger rescheduleInterval;
@property BOOL rescheduleAutomatically;
@property BOOL isDestroyed;
@property(readonly) BOOL isScheduled;
@property NSMutableArray* callbacks;

@end

@interface CLBRemoteOperationScheduler(Overrides)

-(void)operationCompleted:(CLBRemoteResponse*)response;
-(BOOL)shouldIgnoreRequest;

@end
