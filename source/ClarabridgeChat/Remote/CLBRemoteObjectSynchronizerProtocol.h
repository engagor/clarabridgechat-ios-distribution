//
//  CLBRemoteObjectSynchronizerProtocol.h
//  ClarabridgeChat
//
//  Created by Shona Nunez on 10/02/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class CLBRemoteResponse;
@protocol CLBRemoteObject, CLBAPIClientProtocol;

typedef void (^CLBRemoteObjectCompletionBlock)(CLBRemoteResponse * response);

@protocol CLBRemoteObjectSynchronizerProtocol <NSObject>

- (void)fetch:(id<CLBRemoteObject>)object completion:(CLBRemoteObjectCompletionBlock _Nullable)completion;
- (void)synchronize:(id<CLBRemoteObject>)object completion:(CLBRemoteObjectCompletionBlock _Nullable)completion;

@property id<CLBAPIClientProtocol> apiClient;

@end

NS_ASSUME_NONNULL_END
