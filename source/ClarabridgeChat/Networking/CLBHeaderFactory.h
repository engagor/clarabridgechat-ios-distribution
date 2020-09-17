//
//  CLBHeaderFactory.h
//  ClarabridgeChat
//
//  Created by Alan O'Connor on 11/02/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLBSettings;

@interface CLBHeaderFactory : NSObject

+ (NSDictionary *)configAPIClientHeaders;
+ (NSDictionary *)defaultHeadersForAPIClient:(CLBSettings *)settings;
+ (NSDictionary *)authHeadersForAPIClient:(CLBSettings *)settings;

@end

NS_ASSUME_NONNULL_END
