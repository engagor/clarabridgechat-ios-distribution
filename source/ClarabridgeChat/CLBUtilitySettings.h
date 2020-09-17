//
//  CLBUtilitySettings.h
//  ClarabridgeChat
//
//  Created by Shona Nunez on 03/12/2019.
//  Copyright © 2019 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLBUtilitySettings <NSObject>

- (BOOL)isNetworkAvailable;
- (long long)sizeForFile:(NSURL *)fileLocation;
- (long long)messageFileSizeLimit;
- (NSString *)getUniqueDeviceIdentifier;
- (NSDictionary *)serializedClientInfo;

@end

NS_ASSUME_NONNULL_END
