//
//  CLBMessageAction.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBMessageAction+Private.h"

NSString* const CLBMessageActionTypeLink = @"link";
NSString* const CLBMessageActionTypeWebview = @"webview";
NSString* const CLBMessageActionTypeBuy = @"buy";
NSString* const CLBMessageActionTypePostback = @"postback";
NSString* const CLBMessageActionTypeReply = @"reply";
NSString* const CLBMessageActionTypeLocationRequest = @"locationRequest";

NSString* const CLBMessageActionStateOffered = @"offered";
NSString* const CLBMessageActionStatePaid = @"paid";
NSString* const CLBMessageActionUIStateProcessing = @"processing";

NSString* const CLBMessageActionWebviewSizeFull = @"full";
NSString* const CLBMessageActionWebviewSizeTall = @"tall";
NSString* const CLBMessageActionWebviewSizeCompact = @"compact";

static NSString* const kIdKey = @"_id";
static NSString* const kTextKey = @"text";
static NSString* const kURIKey = @"uri";
static NSString* const kFallbackKey = @"fallback";
static NSString* const kTypeKey = @"type";
static NSString* const kCurrencyKey = @"currency";
static NSString* const kAmountKey = @"amount";
static NSString* const kMetadataKey = @"metadata";
static NSString* const kPayloadKey = @"payload";
static NSString* const kStateKey = @"state";
static NSString* const kIconUrlKey = @"iconUrl";
static NSString* const kSizeKey = @"size";
static NSString* const kDefaultKey = @"default";

@interface CLBMessageAction()

@property NSString* uiState;
@property NSString* actionId;
@property BOOL isDefault;

@end

@implementation CLBMessageAction

-(instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if(self){
        _actionId = dictionary[kIdKey];
        _text = dictionary[kTextKey];
        _state = dictionary[kStateKey];

        NSString* urlString = dictionary[kURIKey];
        _uri = [NSURL URLWithString:urlString];

        if(!_uri.scheme){
            _uri = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", urlString]];
        }
        
        NSString *fallbackString = dictionary[kFallbackKey];
        
        if (fallbackString.length > 0) {
            _fallback = [NSURL URLWithString:fallbackString];
            
            if(!_fallback.scheme){
                _fallback = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", fallbackString]];
            }
        }

        _type = dictionary[kTypeKey] ?: CLBMessageActionTypeLink;
        _metadata = dictionary[kMetadataKey];
        _payload = dictionary[kPayloadKey];
        _iconUrl = dictionary[kIconUrlKey];
        _amount = [dictionary[kAmountKey] longValue];
        _currency = dictionary[kCurrencyKey];
        if([_type isEqualToString:CLBMessageActionTypeBuy]){
            _currency = _currency ?: @"usd";
            _state = _state ?: CLBMessageActionStateOffered;
        }
        _size = dictionary[kSizeKey];
        _isDefault = [dictionary[kDefaultKey] boolValue];
    }
    return self;
}

-(id)serialize {
    NSMutableDictionary *serializedAction = [[NSMutableDictionary alloc] init];

    if (self.actionId) {
        [serializedAction setObject:self.actionId forKey:kIdKey];
    }

    if (self.text) {
        [serializedAction setObject:self.text forKey:kTextKey];
    }

    if (self.state) {
        [serializedAction setObject:self.state forKey:kStateKey];
    }

    if (self.uri) {
        [serializedAction setObject:self.uri.absoluteString forKey:kURIKey];
    }
    
    if (self.fallback) {
        [serializedAction setObject:self.fallback.absoluteString forKey:kFallbackKey];
    }

    if (self.type) {
        [serializedAction setObject:self.type forKey:kTypeKey];
    }

    if (self.metadata) {
        [serializedAction setObject:self.metadata forKey:kMetadataKey];
    }

    if (self.payload) {
        [serializedAction setObject:self.payload forKey:kPayloadKey];
    }

    if (self.iconUrl) {
        [serializedAction setObject:self.iconUrl forKey:kIconUrlKey];
    }

    if (self.amount) {
        [serializedAction setObject:[NSNumber numberWithLong:self.amount] forKey:kAmountKey];
    }

    if (self.currency) {
        [serializedAction setObject:self.currency forKey:kCurrencyKey];
    }
    
    if (self.size) {
        [serializedAction setObject:self.size forKey:kSizeKey];
    }
    
    if (self.isDefault) {
        [serializedAction setObject:@(YES) forKey:kDefaultKey];
    }

    return serializedAction;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self){
        _actionId = [aDecoder decodeObjectForKey:kIdKey];
        _text = [aDecoder decodeObjectForKey:kTextKey];
        _uri = [aDecoder decodeObjectForKey:kURIKey];
        _fallback = [aDecoder decodeObjectForKey:kFallbackKey];
        _type = [aDecoder decodeObjectForKey:kTypeKey] ?: CLBMessageActionTypeLink;
        _currency = [aDecoder decodeObjectForKey:kCurrencyKey];
        _metadata = [aDecoder decodeObjectForKey:kMetadataKey];
        _payload = [aDecoder decodeObjectForKey:kPayloadKey];
        _state = [aDecoder decodeObjectForKey:kStateKey];
        _amount = [[aDecoder decodeObjectForKey:kAmountKey] longValue];
        _iconUrl = [aDecoder decodeObjectForKey:kIconUrlKey];

        if([_type isEqualToString:CLBMessageActionTypeBuy]){
            _currency = _currency ?: @"usd";
            _state = _state ?: CLBMessageActionStateOffered;
        }
        
        _size = [aDecoder decodeObjectForKey:kSizeKey];
        _isDefault = [[aDecoder decodeObjectForKey:kDefaultKey] boolValue];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.actionId forKey:kIdKey];
    [aCoder encodeObject:self.text forKey:kTextKey];
    [aCoder encodeObject:self.uri forKey:kURIKey];
    [aCoder encodeObject:self.fallback forKey:kFallbackKey];
    [aCoder encodeObject:self.type forKey:kTypeKey];
    [aCoder encodeObject:self.currency forKey:kCurrencyKey];
    [aCoder encodeObject:@(self.amount) forKey:kAmountKey];
    [aCoder encodeObject:self.metadata forKey:kMetadataKey];
    [aCoder encodeObject:self.payload forKey:kPayloadKey];
    [aCoder encodeObject:self.state forKey:kStateKey];
    [aCoder encodeObject:self.iconUrl forKey:kIconUrlKey];
    [aCoder encodeObject:self.size forKey:kSizeKey];
    [aCoder encodeObject:@(self.isDefault) forKey:kDefaultKey];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[CLBMessageAction class]]) {
        return NO;
    }

    return [self.actionId isEqualToString:((CLBMessageAction *)object).actionId];
}

-(BOOL)isEnabled {
    return !([self.type isEqualToString:CLBMessageActionTypeBuy] && [self.state isEqualToString:CLBMessageActionStatePaid]);
}

-(BOOL)isProcessing {
    return [self.uiState isEqualToString:CLBMessageActionUIStateProcessing];
}

# pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone {
    CLBMessageAction *action = [[CLBMessageAction allocWithZone:zone] init];

    action.actionId = [self.actionId copy];
    action.text = [self.text copy];
    action.uri = [self.uri copy];
    action.fallback = [self.fallback copy];
    action.type = [self.type copy];
    action.currency = [self.currency copy];
    action.amount = self.amount;
    action.metadata = [self.metadata copy];
    action.payload = [self.payload copy];
    action.state = [self.state copy];
    action.iconUrl = [self.iconUrl copy];
    action.size = [self.size copy];
    action.isDefault = self.isDefault;

    return action;
}

# pragma mark - Class methods
+(NSArray*)deserializeActions:(NSArray*)actionObjects {
    if(!actionObjects || actionObjects.count == 0){
        return nil;
    }
    
    NSMutableArray* actions = [NSMutableArray array];
    for(NSDictionary* actionDict in actionObjects){
        CLBMessageAction* action = [[CLBMessageAction alloc] initWithDictionary:actionDict];
        [actions addObject:action];
    }
    
    return [actions copy];
}

@end
