//
//  CLBLocationRequest.h
//  ClarabridgeChat
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CLBMessage.h"

@interface CLBLocationRequest : NSObject

@property CLLocationManager *locationManager;
@property CLBMessage *message;

@end
