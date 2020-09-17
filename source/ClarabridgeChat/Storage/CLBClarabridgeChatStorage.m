//
//  CLBClarabridgeChatStorage.m
//  ClarabridgeChat
//
//  Created by Alan Egan on 22/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import "CLBClarabridgeChatStorage.h"

@interface CLBClarabridgeChatStorage ()

@property (nonatomic) Class aClass;
@property (nonatomic, strong) id<CLBSerializer> serializer;
@property (nonatomic, strong) id<CLBFileIO> fileIO;
@property (nonatomic, strong) id<CLBScopeURLProvider> urlProvider;

@end

@implementation CLBClarabridgeChatStorage

- (nonnull instancetype)initWithClass:(Class)aClass
                           serializer:(id<CLBSerializer>)serializer
                               fileIO:(id<CLBFileIO>)fileIO
                          urlProvider:(id<CLBScopeURLProvider>)urlProvider {
    if (self = [super init]) {
        _aClass = aClass;
        _serializer = serializer;
        _fileIO = fileIO;
        _urlProvider = urlProvider;
    }
    return self;
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key {
    if (!key) {
        return;
    }

    NSData *objectData = [self.serializer serializeObject:object];
    if (objectData) {
        NSURL *url = [self.urlProvider.baseDirectory URLByAppendingPathComponent:key];
        [self.fileIO writeData:objectData toURL:url];
    }
}

- (id _Nullable)objectForKey:(NSString *)key {
    NSURL *url = [self.urlProvider.baseDirectory URLByAppendingPathComponent:key];
    NSData *data = [self.fileIO readDataFromURL:url];
    id object = [self.serializer deserializeData:data forClass:self.aClass];
    
    return object;
}

- (void)removeObjectForKey:(NSString *)key {
    NSURL *url = [self.urlProvider.baseDirectory URLByAppendingPathComponent:key];
    [self.fileIO removeItemAtURL:url];
}

- (void)clear {
    NSError *error;
    [NSFileManager.defaultManager removeItemAtURL:self.urlProvider.baseDirectory error:&error];

    if (error) {
        NSLog(@"<CLARABRIDGECHAT::ERROR> removing file item failed with error: %@", error.localizedDescription);
    }
}

@end
