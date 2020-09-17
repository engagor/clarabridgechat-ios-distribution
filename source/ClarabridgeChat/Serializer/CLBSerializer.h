//
//  CLBSerializer.h
//  ClarabridgeChat
//
//  Created by Alan Egan on 22/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLBSerializer <NSObject>

- (NSData * _Nullable)serializeObject:(id<NSCoding>)object;
- (id _Nullable)deserializeData:(NSData *)data forClass:(Class)class;

@end

NS_ASSUME_NONNULL_END
