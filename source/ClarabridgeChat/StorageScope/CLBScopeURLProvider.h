//
//  CLBScopeURLProvider.h
//  ClarabridgeChat
//
//  Created by Alan Egan on 22/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLBScopeURLProvider <NSObject>

@property (nonatomic, strong, readonly) NSURL *baseDirectory;

@end

NS_ASSUME_NONNULL_END
