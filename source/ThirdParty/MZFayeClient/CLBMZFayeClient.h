//
//  MZFayeClient.h
//  MZFayeClient
//
//  Created by Michał Zaborowski on 12.12.2013.
//  Copyright (c) 2013 Michał Zaborowski. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "CLBSRWebSocket.h"

@class CLBMZFayeClient;

extern NSString *const CLBMZFayeClientBayeuxChannelHandshake;
extern NSString *const CLBMZFayeClientBayeuxChannelConnect;
extern NSString *const CLBMZFayeClientBayeuxChannelDisconnect;
extern NSString *const CLBMZFayeClientBayeuxChannelSubscribe;
extern NSString *const CLBMZFayeClientBayeuxChannelUnsubscribe;

extern NSString *const CLBMZFayeClientWebSocketErrorDomain;
extern NSString *const CLBMZFayeClientBayeuxErrorDomain;
extern NSString *const CLBMZFayeClientErrorDomain;

typedef NS_ENUM(NSInteger, CLBMZFayeClientBayeuxError) {
    CLBMZFayeClientBayeuxErrorReceivedFailureStatus = -100,
    CLBMZFayeClientBayeuxErrorCouldNotParse = -101,
};

typedef NS_ENUM(NSInteger, CLBMZFayeClientError) {
    CLBMZFayeClientErrorAlreadySubscribed,
    CLBMZFayeClientErrorNotSubscribed,
};

extern NSTimeInterval const CLBMZFayeClientDefaultRetryInterval;
extern NSInteger      const CLBMZFayeClientDefaultMaximumAttempts;

typedef void(^CLBMZFayeClientSubscriptionHandler)(NSDictionary *message);

typedef void (^CLBMZFayeClientSuccessHandler)(void);
typedef void (^CLBMZFayeClientFailureHandler)(NSError *error);

@protocol CLBMZFayeClientDelegate <NSObject>
@optional

- (void)fayeClient:(CLBMZFayeClient *)client didConnectToURL:(NSURL *)url;
- (void)fayeClient:(CLBMZFayeClient *)client didDisconnectWithError:(NSError *)error;
- (void)fayeClient:(CLBMZFayeClient *)client didUnsubscribeFromChannel:(NSString *)channel;
- (void)fayeClient:(CLBMZFayeClient *)client didSubscribeToChannel:(NSString *)channel;
- (void)fayeClient:(CLBMZFayeClient *)client didFailWithError:(NSError *)error;
- (void)fayeClient:(CLBMZFayeClient *)client didFailDeserializeMessage:(NSDictionary *)message
         withError:(NSError *)error;
- (void)fayeClient:(CLBMZFayeClient *)client didReceiveMessage:(NSDictionary *)messageData fromChannel:(NSString *)channel;

@end

@interface CLBMZFayeClient : NSObject <CLBSRWebSocketDelegate>

/**
 *  WebSocket client
 */
@property (nonatomic, readonly, strong) CLBSRWebSocket *webSocket;

/**
 *  The URL for the faye server
 */
@property (nonatomic, readonly, strong) NSURL *url;

/**
 *  Uniquely identifies a client to the Bayeux server.
 */
@property (nonatomic, readonly, strong) NSString *clientId;

/**
 *  The number of sent messages
 */
@property (nonatomic, readonly) NSInteger sentMessageCount;

/**
 * Returns whether the faye client is connected to server
 */
@property (nonatomic, readonly, assign, getter = isConnected) BOOL connected;

/**
 *  The channels the client wishes to subscribe
 */
@property (nonatomic, readonly) NSSet *subscriptions;

@property (nonatomic, readonly) NSSet *pendingSubscriptions;
@property (nonatomic, readonly) NSSet *openSubscriptions;

/**
 *  Returns list of extensions per channel.
 *  The contents of ext may be arbitrary values that allow extensions to be negotiated 
 *  and implemented between server and client implementations.
 */
@property (nonatomic, readonly) NSDictionary *extensions;

/**
 * Returns whether the faye client should auto retry connection
 * By default, this is YES
 */
@property (nonatomic, assign) BOOL shouldRetryConnection;

/**
 * How often should retry connection
 */
@property (nonatomic, assign) NSTimeInterval retryInterval;

/**
 * Actual retry connection attempt number
 */
@property (nonatomic, assign) NSInteger retryAttempt;

/**
 * Maximum retry connection attments
 */
@property (nonatomic, assign) NSInteger maximumRetryAttempts;

/**
 *  The object that acts as the delegate of the receiving faye client events.
 */
@property (nonatomic, weak) id <CLBMZFayeClientDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)url;
+ (instancetype)clientWithURL:(NSURL *)url;

- (void)setExtension:(NSDictionary *)extension forChannel:(NSString *)channel;
- (void)removeExtensionForChannel:(NSString *)channel;

- (void)sendMessage:(NSDictionary *)message toChannel:(NSString *)channel success:(CLBMZFayeClientSuccessHandler)successHandler failure:(CLBMZFayeClientFailureHandler)failureHandler;
- (void)sendMessage:(NSDictionary *)message toChannel:(NSString *)channel usingExtension:(NSDictionary *)extension success:(CLBMZFayeClientSuccessHandler)successHandler failure:(CLBMZFayeClientFailureHandler)failureHandler;

- (void)subscribeToChannel:(NSString *)channel success:(CLBMZFayeClientSuccessHandler)successHandler failure:(CLBMZFayeClientFailureHandler)failureHandler receivedMessage:(CLBMZFayeClientSubscriptionHandler)subscriptionHandler;
- (void)unsubscribeFromChannel:(NSString *)channel success:(CLBMZFayeClientSuccessHandler)successHandler failure:(CLBMZFayeClientFailureHandler)failureHandler;

- (void)connect:(CLBMZFayeClientSuccessHandler)successHandler failure:(CLBMZFayeClientFailureHandler)failureHandler;
- (void)forceReconnect;

- (void)disconnect:(CLBMZFayeClientSuccessHandler)successHandler failure:(CLBMZFayeClientFailureHandler)failureHandler;

@end
