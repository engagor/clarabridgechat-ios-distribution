//
//  CLBAuthorInfo.m
//  ClarabridgeChat
//
//  Created by Mike Spensieri on 2019-04-30.
//  Copyright © 2019 Smooch Technologies. All rights reserved.
//

#import "CLBAuthorInfo.h"
#import "CLBUser.h"
#import "CLBClientInfo.h"

@implementation CLBAuthorInfo

+(NSDictionary*)authorFieldForUser:(CLBUser*)user {
    return @{
             @"role": @"appUser",
             @"appUserId": user.appUserId,
             @"client": [CLBClientInfo serializedClientInfo]
             };
}

@end
