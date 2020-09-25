//
//  CLBSettings+CLBSettings_Private.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ClarabridgeChat/CLBSettings.h>

@interface CLBSettings (Private)

@property NSString *configBaseUrl;
@property NSString *sessionToken;
@property NSString *userId;
@property NSString *externalId;
@property NSString *jwt;

- (BOOL)isAuthenticatedUser;

@end
