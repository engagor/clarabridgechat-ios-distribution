//
//  CLBRemoteOperation.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CLBApiClient;
@protocol CLBRemoteObject;

@interface CLBRemoteOperation : NSOperation

-(instancetype)initWithApiClient:(CLBApiClient*)apiClient object:(id<CLBRemoteObject>)object method:(NSString*)method;

@property(nonatomic, copy) void (^doneBlock)(NSHTTPURLResponse *response, NSError *error, id responseObject);

@end
