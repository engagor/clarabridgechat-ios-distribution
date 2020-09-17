//
//  CLBUser+Private.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <ClarabridgeChat/CLBUser.h>
#import "CLBRemoteObject.h"
#import "CLBUserSettings.h"
@class CLBInnerUser;

extern NSString* const CLBUserNSUserDefaultsKey;

@interface CLBUser (Private) < CLBRemoteObject >

@property(readonly) BOOL isModified;
@property CLBInnerUser* localCopy;
@property CLBInnerUser* remoteCopy;
@property NSString* appUserId;
@property NSString* userId;
@property BOOL conversationStarted;
@property(readonly) NSString* fullName;
@property BOOL hasPaymentInfo;
@property BOOL credentialRequired;
@property NSDictionary* cardInfo;
@property (copy) NSString *appId;
@property CLBUserSettings *settings;
@property NSArray<NSDictionary*>* clients;

+(void)setCurrentUser:(CLBUser*)user;

-(void)removeRedundancyFromLocalObject;
-(void)consolidateProperties;
-(void)storeLocalProperties;
-(void)readLocalProperties;
-(void)clearLocalProperties;

@end
