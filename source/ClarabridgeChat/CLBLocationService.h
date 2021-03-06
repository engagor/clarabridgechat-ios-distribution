//
//  CLBLocationService.h
//  ClarabridgeChat
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CLBCoordinates.h"
#import "CLBMessage+Private.h"

@class CLBLocationService;

extern NSInteger const CLBMissingLocationUsageDescriptionError;

@protocol CLBLocationServiceDelegate <NSObject>

@optional

-(void)locationService:(CLBLocationService *)locationService didReceiveAuthorizationResponse:(BOOL)granted;
-(void)locationService:(CLBLocationService *)locationService didStartLocationRequestforMessage:(CLBMessage *)message;
-(void)locationService:(CLBLocationService *)locationService didReceiveCoordinates:(CLBCoordinates *)coordinates forMessage:(CLBMessage *)message;
-(void)locationService:(CLBLocationService *)locationService didFailWithError:(NSError *)error forMessage:(CLBMessage *)message;

@end

@interface CLBLocationService : NSObject

@property(weak) id<CLBLocationServiceDelegate> delegate;

-(instancetype)initWithLocationManager:(CLLocationManager *)locationManager;

-(BOOL)canRequestCurrentLocation;
-(BOOL)isLocationUsageDescriptionProvided;
-(void)requestCurrentLocationForMessage:(CLBMessage *)message;

@end
