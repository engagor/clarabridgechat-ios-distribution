//
//  CLBConfig.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBConfig.h"
#import "CLBUtility.h"

@interface CLBConfig ()
@property (copy, nonatomic) NSString *integrationId;
@end

@implementation CLBConfig

-(instancetype)init {
    self = [super init];

    if (self) {
        _validityStatus = CLBAppStatusUnknown;
    }

    return self;
}

- (instancetype)initWithIntegrationId:(NSString *)integrationId {
    self = [self init];
    if (self) {
        _integrationId = integrationId;
        _retryConfiguration = [[CLBRetryConfiguration alloc] init];
    }
    return self;
}

-(NSString*)remotePath {
    return [NSString stringWithFormat:@"/sdk/v2/integrations/%@/config", self.integrationId];
}

-(id)serialize {
    return nil;
}

-(void)deserialize:(NSDictionary *)object {
    NSDictionary *config = object[@"config"];

    [self deserializeRetryConfiguration:config[@"restRetryPolicy"]];
    self.apiBaseUrl = config[@"baseUrl"][@"ios"];
    self.appId = config[@"app"][@"_id"];
    self.appStatus = config[@"app"][@"status"];
    self.appName = config[@"app"][@"name"];
    self.appIconUrlString = config[@"app"][@"iconUrl"];
    self.acceptedSdkVersion = object[@"acceptedSdkVersion"][@"ios"];

    self.multiConvoEnabled = [config[@"app"][@"settings"][@"multiConvoEnabled"] boolValue];
     self.canUserCreateMoreConversations = [config[@"integration"][@"canUserCreateMoreConversations"] boolValue];
    
    [self deserializeIntegrations:config[@"integrations"]];
}

-(void)deserializeIntegrations:(NSArray *)integrations {
    for (NSDictionary *integration in integrations) {
        if ([integration[@"type"] isEqualToString:@"stripeConnect"]) {
            self.stripeEnabled = YES;
            self.stripePublicKey = integration[@"publicKey"];
        } else if ([integration[@"type"] isEqualToString:@"apn"]) {
            self.pushEnabled = YES;
        }
    }
}

-(void)deserializeRetryConfiguration:(NSDictionary *)retryConfigDict {
    self.retryConfiguration.baseRetryIntervalRegular = retryConfigDict[@"intervals"][@"regular"] ? [retryConfigDict[@"intervals"][@"regular"] intValue] : self.retryConfiguration.baseRetryIntervalRegular;
    self.retryConfiguration.baseRetryIntervalAggressive = retryConfigDict[@"intervals"][@"aggressive"] ? [retryConfigDict[@"intervals"][@"aggressive"] intValue] : self.retryConfiguration.baseRetryIntervalAggressive;
    self.retryConfiguration.maxRetries = retryConfigDict[@"maxRetries"] ? [retryConfigDict[@"maxRetries"] intValue] : self.retryConfiguration.maxRetries;
    self.retryConfiguration.retryBackoffMultiplier = retryConfigDict[@"backoffMultiplier"] ? [retryConfigDict[@"backoffMultiplier"] intValue] : self.retryConfiguration.retryBackoffMultiplier;

    [self.retryConfiguration save];
}

-(BOOL)isAppActive {
    return [self.appStatus isEqualToString:@"active"];
}

-(BOOL)hasValidUrl {
    NSURL *url = [NSURL URLWithString:self.apiBaseUrl];

    return url && ![url.host isEqualToString:@"localhost"];
}

@end
