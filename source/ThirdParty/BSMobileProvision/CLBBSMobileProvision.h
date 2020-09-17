//
//  UIApplication+BSMobileProvision.h
//
//  Created by kaolin fire on 2013-06-24.
//  Copyright (c) 2013 The Blindsight Corporation. All rights reserved.
//  Released under the BSD 2-Clause License (see LICENSE)

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CLBBSMobileProvisionReleaseMode) {
	CLBBSMobileProvisionReleaseUnknown,
	CLBBSMobileProvisionReleaseSim,
	CLBBSMobileProvisionReleaseDev,
	CLBBSMobileProvisionReleaseAdHoc,
	CLBBSMobileProvisionReleaseAppStore,
	CLBBSMobileProvisionReleaseEnterprise,
};

@interface CLBBSMobileProvision : NSObject

+(CLBBSMobileProvisionReleaseMode) releaseMode;
+(NSString *) releaseModeString;

@end
