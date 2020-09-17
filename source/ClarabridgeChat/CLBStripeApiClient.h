//
//  CLBStripeApiClient.h
//  ClarabridgeChat
//
//  Copyright © 2015 Radialpoint. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CLBUser;
@class CLBSTPCardParams;
@class CLBMessageAction;
@class CLBDependencyManager;
@protocol CLBAPIClientProtocol;

@interface CLBStripeApiClient : NSObject

+ (instancetype)newWithDependencies:(CLBDependencyManager*)dependencies;

- (instancetype)initWithStripeHttpClient:(id<CLBAPIClientProtocol>)httpClient
                        clarabridgeChatHttpClient:(id<CLBAPIClientProtocol>)httpClient;

- (void)getCardInfoForUser:(CLBUser*)user completion:(void (^)(NSDictionary* cardInfo))completion;
- (void)getStripeToken:(CLBSTPCardParams*)cardInfo completion:(void (^)(NSString* token))completion;
- (void)createCustomerForUser:(CLBUser*)user withToken:(NSString*)token completion:(void (^)(NSError* error))completion;
- (void)chargeUser:(CLBUser *)user forAction:(CLBMessageAction*)action withToken:(NSString*)token completion:(void (^)(NSError* error))completion;

@property id<CLBAPIClientProtocol> clarabridgeChatHttpClient;
@property id<CLBAPIClientProtocol> stripeHttpClient;

@end
