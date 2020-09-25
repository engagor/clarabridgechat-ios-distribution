#import <Foundation/Foundation.h>
#import "CLBRemoteObject.h"

@interface CLBRemotePushToken : NSObject < CLBRemoteObject >

@property NSString *appId;
@property NSString *userId;
@property NSString *clientId;
@property NSString *pushToken;

@end
