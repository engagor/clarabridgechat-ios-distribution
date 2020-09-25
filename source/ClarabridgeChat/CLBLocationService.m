//
//  CLBLocationService.m
//  ClarabridgeChat
//

#import "CLBLocationService.h"
#import <CoreLocation/CoreLocation.h>
#import "CLBCoordinates.h"
#import "CLBLocationRequest.h"
#import "NSError+ClarabridgeChat.h"

NSInteger const CLBMissingLocationUsageDescriptionError = -5000;

@interface CLBLocationService() <CLLocationManagerDelegate>

@property BOOL pendingAuthorizationForLocationRequest;
@property NSMutableArray<CLBLocationRequest *> *pendingRequests;

@end

@implementation CLBLocationService

-(instancetype)init {
    self = [super init];
    
    if (self) {
        _pendingRequests = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(BOOL)hasRequestLocationPermission {
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
}

-(BOOL)canRequestLocationPermission {
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined;
}

-(void)requestLocationPermissionForMessage:(CLBMessage *)message {
    self.pendingAuthorizationForLocationRequest = YES;
    CLBLocationRequest *pendingRequest = [self requestForMessage:message];
    [self.pendingRequests addObject:pendingRequest];
    
    if ([self isWhenInUseUsageDescriptionProvided]) {
        [pendingRequest.locationManager requestWhenInUseAuthorization];
    } else if ([self isAlwaysUsageDescriptionProvided]) {
        [pendingRequest.locationManager requestAlwaysAuthorization];
    } else {
        self.pendingAuthorizationForLocationRequest = NO;
        NSError *missingUsageDescriptionError = [[NSError alloc] initWithDomain:CLBClarabridgeChatErrorDomain code:CLBMissingLocationUsageDescriptionError userInfo:nil];
        
        [self locationManager:pendingRequest.locationManager didFailWithError:missingUsageDescriptionError];
    }
}

-(BOOL)isWhenInUseUsageDescriptionProvided {
    return [[[NSBundle mainBundle] infoDictionary]objectForKey:@"NSLocationWhenInUseUsageDescription"] != nil;
}

-(BOOL)isAlwaysUsageDescriptionProvided {
    return [[[NSBundle mainBundle] infoDictionary]objectForKey:@"NSLocationAlwaysUsageDescription"] != nil;
}

-(BOOL)isLocationUsageDescriptionProvided {
    return [self isWhenInUseUsageDescriptionProvided] || [self isAlwaysUsageDescriptionProvided];
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (!self.pendingAuthorizationForLocationRequest || status == kCLAuthorizationStatusNotDetermined) {
        // An instance of CLLocationManager has been created and called this method immediately without specifying permission
        return;
    }
    
    BOOL granted = status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways;
    
    CLBLocationRequest *pendingRequest = [self pendingRequestForLocationManager:manager];
    
    if (pendingRequest) {
        
        [self.pendingRequests removeObject:pendingRequest];
        
        if (granted) {
            [self requestCurrentLocationForMessage:pendingRequest.message];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(locationService:didReceiveAuthorizationResponse:)]) {
            [self.delegate locationService:self didReceiveAuthorizationResponse:granted];
        }
    }
    
    self.pendingAuthorizationForLocationRequest = NO;
}

-(BOOL)canRequestCurrentLocation {
    return [self hasRequestLocationPermission] || [self canRequestLocationPermission];
}

-(void)requestCurrentLocationForMessage:(CLBMessage *)message {
    if (!message) {
        return;
    }
    
    if (![self canRequestCurrentLocation]) {
        return;
    }
    
    if ([self canRequestLocationPermission]) {
        [self requestLocationPermissionForMessage:message];
        return;
    }
    
    CLBLocationRequest *pendingRequest = [self requestForMessage:message];
    [self.pendingRequests addObject:pendingRequest];
    [pendingRequest.locationManager requestLocation];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(locationService:didStartLocationRequestforMessage:)]) {
        [self.delegate locationService:self didStartLocationRequestforMessage:pendingRequest.message];
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLBLocationRequest *pendingRequest = [self pendingRequestForLocationManager:manager];
    
    if (pendingRequest && self.delegate && [self.delegate respondsToSelector:@selector(locationService:didReceiveCoordinates:forMessage:)]) {
        [self.pendingRequests removeObject:pendingRequest];
        CLLocation *location = locations[0];
        CLBCoordinates *coordinates = [[CLBCoordinates alloc] initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
        
        pendingRequest.message.coordinates = coordinates;
        [self.delegate locationService:self didReceiveCoordinates:coordinates forMessage:pendingRequest.message];
    }
    
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (error.code == kCLErrorLocationUnknown) {
        // The location service is unable to retrieve a location right away and keeps trying
        return;
    }
    
    CLBLocationRequest *pendingRequest = [self pendingRequestForLocationManager:manager];
    
    if (pendingRequest && self.delegate && [self.delegate respondsToSelector:@selector(locationService:didFailWithError:forMessage:)]) {
        [self.pendingRequests removeObject:pendingRequest];
        [self.delegate locationService:self didFailWithError:error forMessage:pendingRequest.message];
    }
}

-(CLBLocationRequest *)requestForMessage:(CLBMessage *)message {
    CLLocationManager *locationManager = [self newLocationManager];
    locationManager.delegate = self;
    
    CLBLocationRequest *pendingRequest = [[CLBLocationRequest alloc] init];
    pendingRequest.locationManager = locationManager;
    pendingRequest.message = message;
    
    return pendingRequest;
}

-(CLBLocationRequest *)pendingRequestForLocationManager:(CLLocationManager *)manager {
    CLBLocationRequest *pendingRequest;
    
    for (CLBLocationRequest *request in self.pendingRequests) {
        if ([request.locationManager isEqual:manager]) {
            pendingRequest = request;
            break;
        }
    }
    
    return pendingRequest;
}

-(CLLocationManager *)newLocationManager {
    return [[CLLocationManager alloc] init];
}

@end
