//
//  CLBSOLocationMessageCell.m
//  ClarabridgeChat
//

#import "CLBSOLocationMessageCell.h"
#import "CLBRoundedRectView.h"
#import "CLBUtility.h"
#import "CLBLocalization.h"
#import <MapKit/MapKit.h>
#import "CLBMessage+Private.h"

@interface CLBSOLocationMessageCell()

@property UIActivityIndicatorView *activityIndicator;
@property MKMapView* mapView;
@property BOOL locationSet;
@property UITapGestureRecognizer* mapTapGesture;

@end

@implementation CLBSOLocationMessageCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:CLBActivityIndicatorViewStyleGray()];
        
        _mapView = [[MKMapView alloc] init];
        _mapView.rotateEnabled = NO;
        _mapView.scrollEnabled = NO;
        _mapView.pitchEnabled = NO;
        _mapView.zoomEnabled = NO;
        
        _mapTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapViewTapped)];
        [_mapView addGestureRecognizer:_mapTapGesture];
        
        self.bubbleView.layer.masksToBounds = YES;
        [self.bubbleView addSubview:_mapView];
        [self.containerView addSubview:_activityIndicator];
    }
    
    return self;
}

-(void)prepareForReuse {
    [super prepareForReuse];
    
    self.locationSet = NO;
}

-(void)layoutContent {
    [super layoutContent];
    
    CLBMessage* message = (CLBMessage*)self.message;
    
    BOOL triangulatingLocation = ![message hasCoordinates];
    
    if (triangulatingLocation) {
        [self.activityIndicator startAnimating];
        self.activityIndicator.hidden = NO;
        self.mapView.hidden = YES;
    } else {
        [self.activityIndicator stopAnimating];
        self.activityIndicator.hidden = YES;
        self.mapView.hidden = NO;
    }
    
    CGRect frame = CGRectMake(self.bubbleView.frame.origin.x, self.bubbleView.frame.origin.y, 0, 0);
    frame.size = self.mediaImageViewSize;
    
    if (!self.message.isFromCurrentUser && self.userImage) {
        frame.origin.x = kUserImageViewRightMargin + self.userImageViewSize.width;
    }

    self.bubbleView.frame = frame;
    self.mapView.frame = self.bubbleView.bounds;
    
    if (!self.locationSet) {
        MKCoordinateRegion newRegion;
        newRegion.center.latitude = [((CLBMessage*)self.message).coordinates.latitude doubleValue];
        newRegion.center.longitude = [((CLBMessage*)self.message).coordinates.longitude doubleValue];
        newRegion.span.latitudeDelta = 0.003;
        newRegion.span.longitudeDelta = 0.003;
        [self.mapView setRegion:newRegion animated:NO];
        
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        [annotation setCoordinate:newRegion.center];
        [self.mapView addAnnotation:annotation];
        
        self.locationSet = YES;
    }
    
    CGRect viewBounds = self.bubbleView.bounds;
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(viewBounds), CGRectGetMidY(viewBounds));
    
    self.mapTapGesture.enabled = !self.message.failed && self.message.sent;
}

-(void)mapViewTapped {
    double latitude = [((CLBMessage*)self.message).coordinates.latitude doubleValue];
    double longitude = [((CLBMessage*)self.message).coordinates.longitude doubleValue];
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"https://maps.apple.com/?q=%f,%f", latitude, longitude]];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        CLBOpenExternalURL(url);
    }
}

@end
