//
//  CLBConversationMonitor.m
//  ClarabridgeChat
//
//  Copyright © 2015 Radialpoint. All rights reserved.
//

#import "CLBConversationMonitor.h"
#import "CLBMZFayeClient.h"
#import "CLBConfig.h"
#import "ClarabridgeChat+Private.h"
#import "CLBUser+Private.h"
#import "CLBUtility.h"
#import "CLBRealtimeSettings.h"
#import "CLBSettings+Private.h"

NSString* const CLBConversationMonitorDidChangeConnectionStatusNotification = @"CLBConversationMonitorDidChangeConnectionStatusNotification";

@interface CLBConversationMonitor()

@property NSTimer* retryTimer;
@property NSTimer* fayeConnectTimer;
@property int retryNumber;
@property CLBUser *user;
@property CLBConfig *config;

@end

@implementation CLBConversationMonitor

-(instancetype)initWithUser:(CLBUser *)user config:(CLBConfig *)config {
    self = [super init];

    if (self) {
        _retryNumber = 0;
        _user = user;
        _config = config;
    }

    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if(self.retryTimer){
        [self.retryTimer invalidate];
        self.retryTimer = nil;
    }

    if (self.fayeConnectTimer) {
        [self.fayeConnectTimer invalidate];
        self.fayeConnectTimer = nil;
    }
}

-(void)handleReachabilityChanged {
    if(CLBIsNetworkAvailable()){
        [self connect];
    }
}

-(void)notifyConnectionStatusChanged {
    CLBEnsureMainThread(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:CLBConversationMonitorDidChangeConnectionStatusNotification object:self];
    });
}

-(void)setFayeClient:(CLBMZFayeClient *)fayeClient {
    _fayeClient = fayeClient;
    _fayeClient.delegate = self;
}

- (BOOL)shouldStart {
    BOOL userExists = self.user.appUserId != nil;
    BOOL isRealTimeEnabled = self.user.settings != nil && self.user.settings.realtime != nil && self.user.settings.realtime.enabled;
    BOOL isMultiConversationEnabled = self.config.appId != nil && self.config.multiConvoEnabled;
    return userExists && isRealTimeEnabled && (isMultiConversationEnabled || self.user.conversationStarted);
}

-(void)connectImmediately {
    self.user.settings.realtime.enabled = YES;

    [self resetRetryTimer];

    if ([self.fayeConnectTimer isValid]) {
        [self destroyFayeTimer];
        [self startFayeConnectionTimerWithDelay:0];
    } else {
        [self _connectWithFayeDelay:0];
    }
}

-(void)connect {
    if ([self shouldStart]) {
        [self resetRetryTimer];
        [self _connectWithFayeDelay:self.user.settings.realtime.connectionDelay];
    }
}

-(void)destroyFayeTimer {
    if (self.fayeConnectTimer) {
        [self.fayeConnectTimer invalidate];
        self.fayeConnectTimer = nil;
    }
}

-(void)resetRetryTimer {
    if(self.retryTimer){
        [self.retryTimer invalidate];
        self.retryTimer = nil;
    }
    self.retryNumber = 0;
}

-(void)retryConnect {
    self.retryNumber++;

    [self _connectWithFayeDelay:0];
}

-(void)_connectWithFayeDelay:(NSInteger)fayeDelay {
    if (self.isConnected || self.isConnecting || !self.user.settings.realtime.enabled) {
        return;
    }
    if ([self shouldStart]) {
        self.isConnecting = YES;
        [self notifyConnectionStatusChanged];
        [self startFayeConnectionTimerWithDelay:fayeDelay];
    }
}

-(void)startFayeConnectionTimerWithDelay:(NSInteger)delay {
    CLBEnsureMainThread(^{
        self.fayeConnectTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(connectFayeClient:) userInfo:nil repeats:NO];
    });
}

-(void)connectFayeClient:(NSTimer *)timer {
    [self.fayeClient connect:nil failure:nil];
}

-(void)disconnect {
    if(self.fayeClient.isConnected){
        [self.fayeClient disconnect:nil failure:nil];
    }

    [self destroyFayeTimer];
}

-(void)reconnect {
    [self.fayeClient forceReconnect];
}

-(BOOL)isConnected {
    return self.fayeClient.isConnected;
}

#pragma mark - MZFayeClientDelegate

-(void)fayeClient:(CLBMZFayeClient *)client didSubscribeToChannel:(NSString *)channel {
    if([self isValidChannel:channel]){
        self.isConnecting = NO;
        self.didConnectOnce = YES;
        [self notifyConnectionStatusChanged];

        // Pull convo history in case we missed anything while connecting

        if (self.listener) {
            [self.listener onConnectionRefresh];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReachabilityChanged) name:CLBReachabilityStatusChangedNotification object:nil];
    }
}

-(void)fayeClient:(CLBMZFayeClient *)client didConnectToURL:(NSURL *)url {
    NSMutableDictionary* authInfo = [NSMutableDictionary dictionary];

    CLBSettings* settings = [ClarabridgeChat settings];
    authInfo[@"appId"] = settings.appId ?: [NSNull null];
    authInfo[@"appUserId"] = self.user.appUserId ?: [NSNull null];
    
    BOOL hasUserId = settings.userId && settings.userId.length > 0;
    
    if(hasUserId && settings.jwt){
        authInfo[@"jwt"] = settings.jwt;
    } else if (settings.sessionToken) {
        authInfo[@"sessionToken"] = settings.sessionToken;
    }

    NSString *endpoint = [NSString stringWithFormat:@"/sdk/apps/%@/appusers/%@", settings.appId, self.user.appUserId];

    [client setExtension:authInfo forChannel:endpoint];
    [client subscribeToChannel:endpoint success:nil failure:nil receivedMessage:nil];
}

-(void)fayeClient:(CLBMZFayeClient *)client didDisconnectWithError:(NSError *)error {
    self.isConnecting = NO;
    [self notifyConnectionStatusChanged];
}

-(void)fayeClient:(CLBMZFayeClient *)client didFailWithError:(NSError *)error {
    NSString *errorString = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    NSString *unknownClientError = [NSString stringWithFormat:@"401:%@:Unknown client", client.clientId];

    self.isConnecting = NO;

    if ([errorString rangeOfString:unknownClientError].location != NSNotFound && CLBIsNetworkAvailable()) {
        [self reconnect];
    }

    [self notifyConnectionStatusChanged];
}

-(void)fayeClient:(CLBMZFayeClient *)client didReceiveMessage:(NSDictionary *)messageData fromChannel:(NSString *)channel {
    if (self.listener) {
        [self.listener onMessageReceived:messageData fromChannel:channel];
    }
}

-(BOOL)isValidChannel:(NSString *)channel {
    NSString *pattern = @"^/sdk/apps/[\\w\\d]+/appusers/[\\w\\d]+$";

    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:nil];

    return channel && [regex numberOfMatchesInString:channel options:0 range:NSMakeRange(0, [channel length])] > 0;
}

-(BOOL)isWaitingForConnection {
    return [self.fayeConnectTimer isValid];
}

@end
