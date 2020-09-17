//
//  CLBTextViewVendingMachine.h
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CLBSOMessage;

@interface CLBTextViewVendingMachine : NSObject

-(instancetype)initWithCache:(NSCache*)cache;

-(void)setTextForMessage:(id<CLBSOMessage>)message onTextView:(UITextView*)textView withAccentColor:(UIColor*)accentColor userMessageTextColor:(UIColor *)userMessageTextColor;
-(CGSize)sizeForMessage:(id<CLBSOMessage>)message constrainedToWidth:(CGFloat)width;
-(CGSize)sizeForMessage:(id<CLBSOMessage>)message constrainedToWidth:(CGFloat)width usingTextView:(UITextView*)textView;
-(NSString*)textForMessage:(id<CLBSOMessage>)message;
-(UITextView*)newTextView;

@property NSCache* cache;

@end
