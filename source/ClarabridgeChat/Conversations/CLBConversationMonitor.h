//
//  CLBConversationMonitor.h
//  ClarabridgeChat
//
//  Copyright © 2015 Radialpoint. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBMZFayeClient.h"
#import "CLBAuthenticationDelegate.h"

@class CLBConfig;
@class CLBUser;

extern NSString* _Nonnull const CLBConversationMonitorDidChangeConnectionStatusNotification;

@protocol CLBConversationMonitorListener <NSObject>

- (void)onMessageReceived:(NSDictionary * _Nullable)messageData fromChannel:(NSString *_Nullable)channel;
- (void)onConnectionRefresh;

@end

@interface CLBConversationMonitor : NSObject < CLBMZFayeClientDelegate >

-(instancetype _Nullable)initWithUser:(CLBUser * _Nonnull)user config:(CLBConfig * _Nonnull)config
     authenticationDelegate:(_Nullable id<CLBAuthenticationDelegate>)authenticationDelegate;

-(void)connect;
-(void)connectImmediately;
-(void)disconnect;
-(void)reconnect;
-(BOOL)isWaitingForConnection;
-(BOOL)shouldStart;

@property(readonly) BOOL isConnected;
@property BOOL isConnecting;
@property BOOL didConnectOnce;

@property (weak, nullable) id<CLBConversationMonitorListener>listener;
@property (nonatomic, strong, nonnull) CLBMZFayeClient *fayeClient;

@end
