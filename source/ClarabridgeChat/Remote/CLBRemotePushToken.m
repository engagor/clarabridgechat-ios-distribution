#import "CLBRemotePushToken.h"

@implementation CLBRemotePushToken

-(NSString *)remotePath {
    return [NSString stringWithFormat:@"/v2/apps/%@/appusers/%@/clients/%@", self.appId, self.appUserId, self.clientId];
}

-(NSString *)synchronizeMethod {
    return @"PUT";
}

-(id)serialize {
    return @{
             @"pushNotificationToken" : self.pushToken
             };
}

-(void)deserialize:(NSDictionary*)object {}

@end
