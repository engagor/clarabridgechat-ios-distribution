//
//  CLBFileIO.h
//  ClarabridgeChat
//
//  Created by Alan Egan on 22/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLBFileIO <NSObject>

- (void)writeData:(NSData *)data toURL:(NSURL *)url;
- (NSData * _Nullable)readDataFromURL:(NSURL *)url;
- (void)removeItemAtURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
