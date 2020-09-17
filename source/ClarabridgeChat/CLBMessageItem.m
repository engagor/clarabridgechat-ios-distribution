//
//  CLBMessageItem.m
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import "CLBMessageItem+Private.h"
#import "CLBMessageAction+Private.h"

static NSString* const kTitleKey = @"title";
static NSString* const kActionsKey = @"actions";
static NSString* const kDescriptionKey = @"description";
static NSString* const kMediaUrlKey = @"mediaUrl";
static NSString* const kMediaTypeKey = @"mediaType";
static NSString* const kMetadataKey = @"metadata";

@implementation CLBMessageItem

-(instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [self init];
    
    if (self) {
        _title = dictionary[kTitleKey];
        _actions = [CLBMessageAction deserializeActions:dictionary[kActionsKey]];
        _itemDescription = dictionary[kDescriptionKey];
        _mediaUrl = dictionary[kMediaUrlKey];
        _mediaType = dictionary[kMediaTypeKey];
        _metadata = dictionary[kMetadataKey];
    }
    
    return self;
}

-(id)serialize {
    NSMutableDictionary *serializedItem = [NSMutableDictionary new];
    
    if (self.title) {
        [serializedItem setObject:self.title forKey:kTitleKey];
    }
    
    if (self.actions.count > 0) {
        NSMutableArray *actions = [[NSMutableArray alloc] initWithCapacity:self.actions.count];
        
        for (CLBMessageAction *action in self.actions) {
            [actions addObject:[action serialize]];
        }
        
        [serializedItem setObject:actions forKey:kActionsKey];
    }
    
    if (self.itemDescription) {
        [serializedItem setObject:self.itemDescription forKey:kDescriptionKey];
    }
    
    if (self.mediaUrl) {
        [serializedItem setObject:self.mediaUrl forKey:kMediaUrlKey];
    }
    
    if (self.mediaType) {
        [serializedItem setObject:self.mediaType forKey:kMediaTypeKey];
    }
    
    if (self.metadata) {
        [serializedItem setObject:self.metadata forKey:kMetadataKey];
    }
    
    return serializedItem;
}

# pragma mark - NSCoding

-(instancetype)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    
    if (self) {
        _title = [decoder decodeObjectForKey:kTitleKey];
        _actions = [decoder decodeObjectForKey:kActionsKey];
        _itemDescription = [decoder decodeObjectForKey:kDescriptionKey];
        _mediaUrl = [decoder decodeObjectForKey:kMediaUrlKey];
        _mediaType = [decoder decodeObjectForKey:kMediaTypeKey];
        _metadata = [decoder decodeObjectForKey:kMetadataKey];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.title forKey:kTitleKey];
    [coder encodeObject:self.actions forKey:kActionsKey];
    [coder encodeObject:self.itemDescription forKey:kDescriptionKey];
    [coder encodeObject:self.mediaUrl forKey:kMediaUrlKey];
    [coder encodeObject:self.mediaType forKey:kMediaTypeKey];
    [coder encodeObject:self.metadata forKey:kMetadataKey];
}

# pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
    CLBMessageItem *item = [[CLBMessageItem allocWithZone:zone] init];
    
    item.title = [self.title copy];
    item.actions = [[NSArray alloc] initWithArray:self.actions copyItems:YES];
    item.itemDescription = [self.itemDescription copy];
    item.mediaUrl = [self.mediaUrl copy];
    item.mediaType = [self.mediaType copy];
    item.metadata = [self.metadata copy];
    
    return item;
}

@end
