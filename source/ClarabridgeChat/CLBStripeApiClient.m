//
//  CLBStripeApiClient.m
//  ClarabridgeChat
//
//  Copyright © 2015 Radialpoint. All rights reserved.
//

#import "CLBStripeApiClient.h"
#import "CLBApiClient.h"
#import "CLBAPIClientProtocol.h"
#import "CLBSTPCardParams.h"
#import "CLBUser+Private.h"
#import "CLBMessageAction.h"
#import "CLBQueryStringSerializer.h"
#import "CLBDependencyManager.h"
#import "CLBConfig.h"
#import "CLBRemoteObjectSynchronizer.h"

static NSString* const kStripeUrl = @"/v1/tokens";
static NSString* const kTransactionPath = @"/stripe/transaction";
static NSString* const kCustomerPath = @"/stripe/customer";

@implementation CLBStripeApiClient

+(instancetype)newWithDependencies:(CLBDependencyManager *)dependencies {
    CLBApiClient* stripeHttpClient = [[CLBApiClient alloc] initWithBaseURL:@"https://api.stripe.com"];
    stripeHttpClient.requestSerializer = [[CLBQueryStringSerializer alloc] init];

    NSString *authStr = [NSString stringWithFormat:@"%@:", dependencies.config.stripePublicKey];
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
    
    stripeHttpClient.headersBlock = ^NSDictionary *{
        return @{
                 @"Authorization": authValue
                 };
    };

    return [[CLBStripeApiClient alloc] initWithStripeHttpClient:stripeHttpClient clarabridgeChatHttpClient:dependencies.synchronizer.apiClient];
}

-(instancetype)initWithStripeHttpClient:(id<CLBAPIClientProtocol>)stripeHttpClient
                       clarabridgeChatHttpClient:(id<CLBAPIClientProtocol>)clarabridgeChatHttpClient {
    self = [super init];
    if(self){
        _clarabridgeChatHttpClient = clarabridgeChatHttpClient;
        _stripeHttpClient = stripeHttpClient;
    }
    return self;
}

-(void)getCardInfoForUser:(CLBUser *)user completion:(void (^)(NSDictionary *))completion {
    NSString* url = [[user remotePath] stringByAppendingString:kCustomerPath];

    [self.clarabridgeChatHttpClient GET:url parameters:nil completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        if(error){
            completion(nil);
        }else{
            completion(responseObject[@"card"]);
        }
    }];
}

-(void)getStripeToken:(CLBSTPCardParams*)cardInfo completion:(void (^)(NSString* token))completion {
    NSDictionary* postBody = @{
                               @"card" : @{
                                       @"number" : cardInfo.number,
                                       @"exp_month" : @(cardInfo.expMonth),
                                       @"exp_year" : @(cardInfo.expYear),
                                       @"cvc" : cardInfo.cvc
                                       }
                               };

    [self.stripeHttpClient requestWithMethod:@"POST"
                                         url:kStripeUrl
                                  parameters:postBody
                                  completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                                      if(error){
                                          completion(nil);
                                      }else{
                                          completion(responseObject[@"id"]);
                                      }
                                  }];
}

-(void)createCustomerForUser:(CLBUser*)user withToken:(NSString*)token completion:(void (^)(NSError* error))completion {
    NSParameterAssert(token);

    NSString* url = [[user remotePath] stringByAppendingString:kCustomerPath];

    [self.clarabridgeChatHttpClient requestWithMethod:@"POST"
                                         url:url
                                  parameters:@{
                                               @"token" : token
                                               }
                                  completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                                      if(error){
                                          completion(error);
                                      }else{
                                          completion(nil);
                                      }
                                  }];
}

-(void)chargeUser:(CLBUser *)user forAction:(CLBMessageAction*)action withToken:(NSString*)token completion:(void (^)(NSError* error))completion {
    NSString* url = [[user remotePath] stringByAppendingString:kTransactionPath];

    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                  @"actionId" : action.actionId
                                                                                  }];

    if(token){
        params[@"token"] = token;
    }

    [self.clarabridgeChatHttpClient requestWithMethod:@"POST"
                                         url:url
                                  parameters:params
                                  completion:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                                      completion(error);
                                  }];
}

@end
