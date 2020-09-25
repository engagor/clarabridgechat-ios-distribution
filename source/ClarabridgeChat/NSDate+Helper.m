//
//  NSDate+NSDate_Helper.m
//  ClarabridgeChat
//
//  Created by Conor Nolan on 22/05/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "NSDate+Helper.h"
#import "CLBLocalization.h"

@implementation NSDate (Helper)

- (NSString *)relativeDateAsString {
    NSDate *referenceDate = self;
    NSDate *currentDate = [NSDate date];
    NSCalendarUnit units = NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay;

    NSDateComponents *components = [[NSCalendar currentCalendar] components:units
                                                                   fromDate:referenceDate
                                                                     toDate:currentDate
                                                                    options:0];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    NSString *referenceDateAsString = [dateFormatter stringFromDate:referenceDate];


    if (components.day >= 1) {
        return components.day == 1 ? [NSString stringWithFormat:@"%@", [CLBLocalization localizedStringForKey:@"Yesterday"]] : referenceDateAsString;
    } else if (components.hour >= 1) {
        return components.hour == 1 ? [NSString stringWithFormat:@"%@", [CLBLocalization localizedStringForKey:@"1 hour ago"]] : [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"%ld hours ago"], (long)components.hour];
    } else {
        return components.minute <= 1 ? [NSString stringWithFormat:@"%@", [CLBLocalization localizedStringForKey:@"Just now"]] :  [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"%ld minutes ago"], (long)components.minute];
    }
}

@end
