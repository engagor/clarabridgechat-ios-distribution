//
//  CLBRemoteObjectSynchronizer.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBRemoteObjectSynchronizerProtocol.h"

@protocol CLBAPIClientProtocol;

@interface CLBRemoteObjectSynchronizer : NSObject <CLBRemoteObjectSynchronizerProtocol>

- (instancetype)initWithApiClient:(id<CLBAPIClientProtocol>)apiClient;

@property id<CLBAPIClientProtocol> apiClient;

@end
