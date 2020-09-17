//
//  CLBLocalization.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBLocalization.h"
#import "ClarabridgeChat+Private.h"

static NSString* const kStringFile = @"ClarabridgeChatLocalizable";
static NSString* const kNotFound = @"StringNotFound";

@implementation CLBLocalization

+(NSString*)localizedStringForKey:(NSString*)key {
    NSString* localized = [[NSBundle mainBundle] localizedStringForKey:key value:kNotFound table:kStringFile];

    if(localized && ![localized isEqualToString:kNotFound]){
        return localized;
    }

    localized = [[ClarabridgeChat getResourceBundle] localizedStringForKey:key value:kNotFound table:kStringFile];

    if(localized && ![localized isEqualToString:kNotFound]){
        return localized;
    }

    return key;
}

@end
