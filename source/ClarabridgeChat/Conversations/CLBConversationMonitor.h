//
//  CLBConversationMonitor.h
//  ClarabridgeChat
//
//  Copyright © 2015 Radialpoint. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBMZFayeClient.h"

@class CLBConfig;
@class CLBUser;

extern NSString* const CLBConversationMonitorDidChangeConnectionStatusNotification;

@protocol CLBConversationMonitorListener <NSObject>

- (void)onMessageReceived:(NSDictionary *)messageData fromChannel:(NSString *)channel;
- (void)onConnectionRefresh;

@end

@interface CLBConversationMonitor : NSObject < CLBMZFayeClientDelegate >

-(instancetype)initWithUser:(CLBUser *)user config:(CLBConfig *)config;

-(void)connect;
-(void)connectImmediately;
-(void)disconnect;
-(void)reconnect;
-(BOOL)isWaitingForConnection;
-(BOOL)shouldStart;

@property(readonly) BOOL isConnected;
@property BOOL isConnecting;
@property BOOL didConnectOnce;

@property (weak) id<CLBConversationMonitorListener>listener;
@property (nonatomic, strong) CLBMZFayeClient *fayeClient;

@end
