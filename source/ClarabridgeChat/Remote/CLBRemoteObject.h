//
//  CLBRemoteObject.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CLBRemoteObject <NSObject>

-(id)serialize;
-(NSString*)remotePath;
-(void)deserialize:(NSDictionary*)object;

@optional

-(NSString*)fetchMethod;
-(NSString*)synchronizeMethod;

@end
