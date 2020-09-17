//
//  CLBStorage.h
//  ClarabridgeChat
//
//  Created by Alan Egan on 20/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLBSerializer.h"
#import "CLBScopeURLProvider.h"
#import "CLBFileIO.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CLBStorage <NSObject>

- (instancetype)initWithClass:(Class)aClass
                   serializer:(id<CLBSerializer>)serializer
                       fileIO:(id<CLBFileIO>)fileIO
                  urlProvider:(id<CLBScopeURLProvider>)urlProvider;
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key;
- (id _Nullable)objectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (void)clear;

@end

NS_ASSUME_NONNULL_END
