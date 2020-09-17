//
//  CLBClarabridgeChatSerializer.m
//  ClarabridgeChat
//
//  Created by Alan Egan on 22/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import "CLBClarabridgeChatSerializer.h"

@implementation CLBClarabridgeChatSerializer

- (NSData * _Nullable)serializeObject:(id<NSCoding>)object {
    NSData *data;
    if (@available(iOS 11.0, *)) {
        NSError *error;
        data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:NO error:&error];

        if (error) {
            NSLog(@"<CLARABRIDGECHAT::ERROR> failed to archive object with error: %@", error.localizedDescription);
        }
    } else {
        data = [NSKeyedArchiver archivedDataWithRootObject:object];
    }
    return data;
}

- (id _Nullable)deserializeData:(NSData *)data forClass:(Class)class {

    @try {
//        if (@available(iOS 11.0, *)) { 
//            NSError *error;
//            id object = [NSKeyedUnarchiver unarchivedObjectOfClass:class fromData:data error:&error];
//            return object;
//        } else {
            id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            return object;
//        }
    } @catch (NSException *exception) {
        return nil;
    }
}

@end
