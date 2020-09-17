//
//  CLBClarabridgeChatFileIO.m
//  ClarabridgeChat
//
//  Created by Alan Egan on 22/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import "CLBClarabridgeChatFileIO.h"

@implementation CLBClarabridgeChatFileIO

- (void)writeData:(NSData *)data toURL:(NSURL *)url {
    [data writeToURL:url atomically:YES];
}

- (NSData * _Nullable)readDataFromURL:(NSURL *)url {

    NSError *error;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:url error:&error];
    if (error || fileHandle == nil) {
        return nil;
    }

    return [fileHandle readDataToEndOfFile];
}

- (void)removeItemAtURL:(NSURL *)url {
    [NSFileManager.defaultManager removeItemAtURL:url error:nil];
}

@end
