//
//  CLBPersistence.h
//  ClarabridgeChat
//
//  Created by Mike Spensieri on 2018-01-26.
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLBPersistence : NSObject

+(instancetype)sharedPersistence;
+(void)setSharedPersistence:(CLBPersistence*)persistence;

-(instancetype)initWithApplication:(UIApplication*)sharedApplication;

-(void)ensureProtectedDataAvailable:(void (^)(void))block;

-(NSString*)getValueFromKeychain:(NSString*)key;
-(NSString*)getValueFromUserDefaults:(NSString*)key;

-(BOOL)persistValue:(NSString*)value inKeychain:(NSString*)key;
-(void)persistValue:(NSString*)value inUserDefaults:(NSString*)key;

-(BOOL)removeValueFromKeychain:(NSString*)key;
-(void)removeValueFromUserDefaults:(NSString*)key;

@end
