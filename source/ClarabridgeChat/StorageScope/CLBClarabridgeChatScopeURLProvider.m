//
//  CLBClarabridgeChatScopeURLProvider.m
//  ClarabridgeChat
//
//  Created by Alan Egan on 22/11/2019.
//  Copyright © 2019 Zendesk. All rights reserved.
//

#import "CLBClarabridgeChatScopeURLProvider.h"

NSString * const CLBSunshineConversationsDomain = @"com.zendesk.sunshine.conversations";

@interface CLBClarabridgeChatScopeURLProvider ()

@property (nonatomic, strong) NSString *baseScopePath;

@end

@implementation CLBClarabridgeChatScopeURLProvider

- (instancetype)initWithScopePath:(NSString *)baseScopePath {
    if (self = [super init]) {
        _baseScopePath = baseScopePath;
    }
    return self;
}

- (NSURL *)documentsDirectory {
    NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                               inDomains:NSUserDomainMask] lastObject];
    return documents;
}

- (NSURL *)sunshineConversationsDirectory {
    return [self.documentsDirectory URLByAppendingPathComponent:CLBSunshineConversationsDomain isDirectory:YES];
}

- (NSURL *)baseDirectory {
    if (self.baseScopePath.length == 0) {
        return [NSURL URLWithString:self.baseScopePath];
    }

    NSURL * baseScopeURL = [self.sunshineConversationsDirectory URLByAppendingPathComponent:self.baseScopePath
                                                                                isDirectory:YES];
    if ([self scopeNeedsDirectory:baseScopeURL]) {
        [self createScopeDirectory:baseScopeURL];
    }

    return baseScopeURL;
}

- (BOOL)scopeNeedsDirectory:(NSURL *)url {
    if (!url) {
        return NO;
    }

    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithURL:url options:0 error:nil];
    return wrapper == nil;
}

- (void)createScopeDirectory:(NSURL *)url {
    if (!url) {
        return;
    }

    NSError *error;
    [NSFileManager.defaultManager createDirectoryAtURL:url
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:&error];

    if (error) {
        NSLog(@"<CLARABRIDGECHAT::ERROR> failed to create directory: %@", error.localizedDescription);
    }
}

@end
