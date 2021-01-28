#import "CLBRemotePushToken.h"

@implementation CLBRemotePushToken

-(NSString *)remotePath {
    return [NSString stringWithFormat:@"/v2/apps/%@/appusers/%@/clients/%@", self.appId, self.userId, self.clientId];
}

-(NSString *)synchronizeMethod {
    return @"PUT";
}

-(id)serialize {
    return @{
             @"pushNotificationToken" : self.pushToken,
             @"integrationId": self.integrationId
             };
}

-(void)deserialize:(NSDictionary*)object {}

@end
