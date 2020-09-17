//
//  CLBMessageItemViewModel.h
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CLBRoundedRectView.h"

@interface CLBMessageItemViewModel : NSObject

// Data
@property NSString *text;
@property NSString *itemDescription;
@property NSArray *actions;
@property NSString *mediaUrl;

// Appearance
@property CLBCorners flatCorners;
@property CGSize imageViewSize;
@property CGFloat messageMaxWidth;
@property CGFloat preferredContentWidth;
@property CGFloat preferredContentHeight;
@property UIColor *accentColor;
@property UIColor *actionsSeparatorColor;
@property UIFont *actionButtonFont;
@property UIColor *actionButtonBackgroundColor;
@property UIColor *actionButtonEnabledColor;
@property UIColor *actionButtonHighlightedColor;
@property UIColor *actionButtonDisabledColor;
@property CGFloat actionsContainerTopPadding;
@property CGFloat actionsButtonHeight;
@property CGFloat actionButtonSeparatorHeight;
@property CGFloat actionButtonSeparatorPadding;
@property NSString *actionButtonDisabledText;
@property UIColor *backgroundColor;
@property UIColor *titleTextColor;
@property UIColor *descriptionTextColor;
@property CGFloat titleFontSize;
@property CGFloat descriptionFontSize;
@property CGFloat textLineSpacing;
@property CGFloat borderWith;
@property CGFloat borderArea;

@end
