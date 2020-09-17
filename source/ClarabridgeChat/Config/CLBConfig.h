//
//  CLBConfig.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBRemoteObject.h"
#import "CLBRetryConfiguration.h"
#import "CLBRealtimeSettings.h"

typedef NS_ENUM(NSUInteger, CLBAppValidityStatus){
    CLBAppStatusUnknown,
    CLBAppStatusValid,
    CLBAppStatusInvalid
};

@interface CLBConfig : NSObject < CLBRemoteObject >

@property (copy, nonatomic, readonly) NSString *integrationId;
@property (copy, nonatomic) NSString *appId;
@property (copy, nonatomic) NSString *appStatus;
@property (copy, nonatomic) NSString *appName;
@property (copy, nonatomic) NSString *acceptedSdkVersion;
@property BOOL pushEnabled;
@property BOOL multiConvoEnabled;
@property CLBAppValidityStatus validityStatus;

@property (strong, nonatomic) CLBRetryConfiguration *retryConfiguration;
@property (copy, nonatomic) NSString *apiBaseUrl;

@property BOOL stripeEnabled;
@property (copy, nonatomic) NSString *stripePublicKey;

- (instancetype)initWithIntegrationId:(NSString *)integrationId;
-(BOOL)isAppActive;
-(BOOL)hasValidUrl;

@end
