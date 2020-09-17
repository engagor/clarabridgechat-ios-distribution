//
//  CLBBuyViewController.h
//  ClarabridgeChat
//
//  Copyright © 2015 Radialpoint. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CLBMessageAction;
@class CLBStripeApiClient;
@class CLBUser;
@class CLBMessage;
@protocol CLBBuyViewControllerDelegate;

@interface CLBBuyViewController : UIViewController

-(instancetype)initWithAction:(CLBMessageAction*)action user:(CLBUser*)user apiClient:(CLBStripeApiClient*)apiClient;

@property CLBUser* user;
@property CLBMessageAction* action;
@property CLBStripeApiClient* apiClient;
@property CLBMessage* message;

@property(weak) id<CLBBuyViewControllerDelegate> delegate;
@property UIColor* accentColor;

@end

@protocol CLBBuyViewControllerDelegate <NSObject>

@optional
-(void)buyViewControllerDidDismissWithPurchase:(CLBBuyViewController*)viewController;

@end
