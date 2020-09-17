//
//  CLBRemoteOperationScheduler.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBRemoteOperationScheduler.h"
#import "CLBRemoteObjectSynchronizer.h"
#import "CLBRemoteObject.h"
#import "CLBUtility.h"

NSString* const CLBRemoteOperationSchedulerStartedNotification = @"CLBRemoteOperationSchedulerStartedNotification";
NSString* const CLBRemoteOperationSchedulerCompletedNotification = @"CLBRemoteOperationSchedulerCompletedNotification";

@interface CLBRemoteOperationScheduler()

@property NSDate* retryStopTime;
@property NSTimer* retryTimer;

@end

@implementation CLBRemoteOperationScheduler

-(instancetype)initWithRemoteObject:(id<CLBRemoteObject>)object synchronizer:(CLBRemoteObjectSynchronizer *)synchronizer {
    self = [super init];
    if(self){
        _remoteObject = object;
        _synchronizer = synchronizer;
        _callbacks = [NSMutableArray array];
        _type = CLBRemoteOperationSchedulerTypeFetch;
        _isDestroyed = NO;
    }
    return self;
}

-(void)addCallbackOnNextFetch:(void (^)(CLBRemoteResponse*))callback {
    @synchronized(self){
        if(callback){
            [self.callbacks addObject:callback];
        }
    }
}

-(void)scheduleImmediately {
    [self execute];
}

-(void)execute {
    [self cancelTimer];

    @synchronized(self){
        if(self.isExecuting || self.isDestroyed){
            return;
        }
    }

    if([self shouldIgnoreRequest]){
        if(self.rescheduleAutomatically && self.rescheduleInterval){
            [self scheduleAfter:self.rescheduleInterval];
        }
        return;
    }

    @synchronized(self){
        self.isExecuting = YES;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CLBRemoteOperationSchedulerStartedNotification object:self];

    void (^completionBlock)(CLBRemoteResponse* response) = ^(CLBRemoteResponse* response){
        [self operationCompleted:response];
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBRemoteOperationSchedulerCompletedNotification object:self];

        NSArray* callbacks;
        @synchronized(self){
            callbacks = [NSArray arrayWithArray:self.callbacks];
            self.isExecuting = NO;
            self.callbacks = [NSMutableArray array];
        }

        for(void (^callback)(CLBRemoteResponse*) in callbacks){
            callback(response);
        }

        if(self.rescheduleAutomatically && self.rescheduleInterval){
            [self scheduleAfter:self.rescheduleInterval];
        }
    };

    if(self.type == CLBRemoteOperationSchedulerTypeFetch){
        [self.synchronizer fetch:self.remoteObject completion:completionBlock];
    }else{
        [self.synchronizer synchronize:self.remoteObject completion:completionBlock];
    }
}

-(void)scheduleAfter:(NSUInteger)seconds {
    CLBEnsureMainThread(^{
        @synchronized(self){
            if(self.isDestroyed){
                return;
            }
        }

        [self cancelTimer];

        // Cannot schedule timer on a short-lived thread or it won't fire
        self.retryTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(execute) userInfo:nil repeats:NO];
    });
}

-(void)restore {
    @synchronized (self) {
        self.isDestroyed = NO;
    }
}

-(void)destroy {
    @synchronized(self) {
        self.isDestroyed = YES;
    }

    [self cancelTimer];
}

-(void)cancelTimer {
    CLBEnsureMainThread(^{
        // Timers must be invalidated from the thread they were created on
        if([self.retryTimer isValid]){
            [self.retryTimer invalidate];
            self.retryTimer = nil;
        }
    });
}

-(void)operationCompleted:(CLBRemoteResponse *)response {
    // Override to perform custom actions
}

-(BOOL)shouldIgnoreRequest {
    return NO;
}

-(BOOL)isScheduled {
    return self.retryTimer != nil;
}

@end
