//
//  CLBClarabridgeChatUtilitySettings.m
//  ClarabridgeChat
//
//  Created by Shona Nunez on 03/12/2019.
//  Copyright © 2019 Smooch Technologies. All rights reserved.
//

#import "CLBClarabridgeChatUtilitySettings.h"
#import "CLBUtility.h"
#import "CLBMessage+Private.h"
#import "CLBClientInfo.h"

@implementation CLBClarabridgeChatUtilitySettings

- (BOOL)isNetworkAvailable {
    return CLBIsNetworkAvailable();
}

- (long long)sizeForFile:(NSURL *)fileLocation {
    return CLBSizeForFile(fileLocation);
}

- (long long)messageFileSizeLimit {
    return CLBMessageFileSizeLimit;
}

- (NSString *)getUniqueDeviceIdentifier {
    return CLBGetUniqueDeviceIdentifier();
}

- (NSDictionary *)serializedClientInfo {
    return [CLBClientInfo serializedClientInfo];
}

@end
