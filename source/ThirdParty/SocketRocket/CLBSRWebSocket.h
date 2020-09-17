//
//   Copyright 2012 Square Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

//
//   Modifications copyright (c) 2017 Smooch Technologies.
//

#import <Foundation/Foundation.h>
#import <Security/SecCertificate.h>

typedef NS_ENUM(NSInteger, CLBSRReadyState) {
    CLBSR_CONNECTING   = 0,
    CLBSR_OPEN         = 1,
    CLBSR_CLOSING      = 2,
    CLBSR_CLOSED       = 3,
};

typedef enum CLBSRStatusCode : NSInteger {
    // 0–999: Reserved and not used.
    CLBSRStatusCodeNormal = 1000,
    CLBSRStatusCodeGoingAway = 1001,
    CLBSRStatusCodeProtocolError = 1002,
    CLBSRStatusCodeUnhandledType = 1003,
    // 1004 reserved.
    CLBSRStatusNoStatusReceived = 1005,
    CLBSRStatusCodeAbnormal = 1006,
    CLBSRStatusCodeInvalidUTF8 = 1007,
    CLBSRStatusCodePolicyViolated = 1008,
    CLBSRStatusCodeMessageTooBig = 1009,
    CLBSRStatusCodeMissingExtension = 1010,
    CLBSRStatusCodeInternalError = 1011,
    CLBSRStatusCodeServiceRestart = 1012,
    CLBSRStatusCodeTryAgainLater = 1013,
    // 1014: Reserved for future use by the WebSocket standard.
    CLBSRStatusCodeTLSHandshake = 1015,
    // 1016–1999: Reserved for future use by the WebSocket standard.
    // 2000–2999: Reserved for use by WebSocket extensions.
    // 3000–3999: Available for use by libraries and frameworks. May not be used by applications. Available for registration at the IANA via first-come, first-serve.
    // 4000–4999: Available for use by applications.
} CLBSRStatusCode;

@class CLBSRWebSocket;

extern NSString *const CLBSRWebSocketErrorDomain;
extern NSString *const CLBSRHTTPResponseErrorKey;

#pragma mark - CLBSRWebSocketDelegate

@protocol CLBSRWebSocketDelegate;

#pragma mark - CLBSRWebSocket

@interface CLBSRWebSocket : NSObject <NSStreamDelegate>

@property (nonatomic, weak) id <CLBSRWebSocketDelegate> delegate;

@property (nonatomic, readonly) CLBSRReadyState readyState;
@property (nonatomic, readonly, retain) NSURL *url;


@property (nonatomic, readonly) CFHTTPMessageRef receivedHTTPHeaders;

// Optional array of cookies (NSHTTPCookie objects) to apply to the connections
@property (nonatomic, readwrite) NSArray * requestCookies;

// This returns the negotiated protocol.
// It will be nil until after the handshake completes.
@property (nonatomic, readonly, copy) NSString *protocol;

// Protocols should be an array of strings that turn into Sec-WebSocket-Protocol.
- (id)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray *)protocols allowsUntrustedSSLCertificates:(BOOL)allowsUntrustedSSLCertificates;
- (id)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray *)protocols;
- (id)initWithURLRequest:(NSURLRequest *)request;

// Some helper constructors.
- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols allowsUntrustedSSLCertificates:(BOOL)allowsUntrustedSSLCertificates;
- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols;
- (id)initWithURL:(NSURL *)url;

// Delegate queue will be dispatch_main_queue by default.
// You cannot set both OperationQueue and dispatch_queue.
- (void)setDelegateOperationQueue:(NSOperationQueue*) queue;
- (void)setDelegateDispatchQueue:(dispatch_queue_t) queue;

// By default, it will schedule itself on +[NSRunLoop CLBSR_networkRunLoop] using defaultModes.
- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;
- (void)unscheduleFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;

// CLBSRWebSockets are intended for one-time-use only.  Open should be called once and only once.
- (void)open;

- (void)close;
- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason;

// Send a UTF8 String or Data.
- (void)send:(id)data;

// Send Data (can be nil) in a ping message.
- (void)sendPing:(NSData *)data;

@end

#pragma mark - CLBSRWebSocketDelegate

@protocol CLBSRWebSocketDelegate <NSObject>

// message will either be an NSString if the server is using text
// or NSData if the server is using binary.
- (void)webSocket:(CLBSRWebSocket *)webSocket didReceiveMessage:(id)message;

@optional

- (void)webSocketDidOpen:(CLBSRWebSocket *)webSocket;
- (void)webSocket:(CLBSRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(CLBSRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
- (void)webSocket:(CLBSRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;

// Return YES to convert messages sent as Text to an NSString. Return NO to skip NSData -> NSString conversion for Text messages. Defaults to YES.
- (BOOL)webSocketShouldConvertTextFrameToString:(CLBSRWebSocket *)webSocket;

@end

#pragma mark - NSURLRequest (CLBSRCertificateAdditions)

@interface NSURLRequest (CLBSRCertificateAdditions)

@property (nonatomic, retain, readonly) NSArray *CLBSR_SSLPinnedCertificates;

@end

#pragma mark - NSMutableURLRequest (CLBSRCertificateAdditions)

@interface NSMutableURLRequest (CLBSRCertificateAdditions)

@property (nonatomic, retain) NSArray *CLBSR_SSLPinnedCertificates;

@end

#pragma mark - NSRunLoop (CLBSRWebSocket)

@interface NSRunLoop (CLBSRWebSocket)

+ (NSRunLoop *)CLBSR_networkRunLoop;

@end
