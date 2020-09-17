//
//  CLBAuthorInfo.h
//  ClarabridgeChat
//
//  Created by Mike Spensieri on 2019-04-30.
//  Copyright © 2019 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLBUser;
NS_ASSUME_NONNULL_BEGIN

@interface CLBAuthorInfo : NSObject

+ (NSDictionary *)authorFieldForUser:(CLBUser *)user;

@end

NS_ASSUME_NONNULL_END
