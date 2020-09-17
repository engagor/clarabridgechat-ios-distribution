//
//  CLBTextViewVendingMachine.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBTextViewVendingMachine.h"
#import "CLBSOMessage.h"
#import "CLBUtility.h"
#import "CLBMessage.h"
#import "CLBLocalization.h"

static const CGFloat kFontSize = 16;
static const CGFloat kLineSpacing = 1.05;

@interface CLBTextViewVendingMachine()

@property(readonly) UITextView* textMeasurementView;

@end

@implementation CLBTextViewVendingMachine
@synthesize textMeasurementView = _textMeasurementView;

-(instancetype)init {
    return [self initWithCache:[[NSCache alloc] init]];
}

-(instancetype)initWithCache:(NSCache*)cache {
    self = [super init];
    if(self){
        _cache = cache;
    }
    return self;
}

-(UITextView*)textMeasurementView {
    if(!_textMeasurementView){
        _textMeasurementView = [[self class] newTextViewInternal];
        _textMeasurementView.dataDetectorTypes = UIDataDetectorTypeNone;
    }
    return _textMeasurementView;
}

-(CGSize)sizeForMessage:(id<CLBSOMessage>)message constrainedToWidth:(CGFloat)width {
    return [self sizeForMessage:message constrainedToWidth:width usingTextView:nil];
}

-(CGSize)sizeForMessage:(id<CLBSOMessage>)message constrainedToWidth:(CGFloat)width usingTextView:(UITextView*)textView {
    NSString* text = [self textForMessage:message];
    
    if (!text) {
        return CGSizeZero;
    }

    NSMutableDictionary* cacheForWidth = [self.cache objectForKey:@(width)];
    if(cacheForWidth){
        CGSize cachedSize = [cacheForWidth[text] CGSizeValue];

        if(!CGSizeEqualToSize(cachedSize, CGSizeZero)){
            return cachedSize;
        }
    }else{
        cacheForWidth = [NSMutableDictionary dictionary];
        [self.cache setObject:cacheForWidth forKey:@(width)];
    }

    if(!textView){
        textView = self.textMeasurementView;
        [self setTextForMessage:message onTextView:self.textMeasurementView withAccentColor:[UIColor clearColor] userMessageTextColor:CLBDefaultUserMessageTextColor()];
    }
    CGSize computedSize = [textView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];

    cacheForWidth[text] = [NSValue valueWithCGSize:computedSize];

    return computedSize;
}

-(void)setTextForMessage:(id<CLBSOMessage>)message onTextView:(UITextView*)textView withAccentColor:(UIColor*)accentColor userMessageTextColor:(UIColor *)userMessageTextColor {
    NSString* text = [self textForMessage:message];
    
    if (!text) {
        return;
    }

    // BUG FIX : UITextView sometimes retains data detector links in iOS7, so we have to use attributedText rather than text
    // See here http://stackoverflow.com/a/20669356/3482071

    UIColor* textColor = message.isFromCurrentUser ? userMessageTextColor : CLBExtraDarkGrayColor(YES);
    static UIFont* font;
    if(!font){
        font = [UITextView appearance].font ?: [UIFont systemFontOfSize:kFontSize];
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = kLineSpacing;

    textView.linkTextAttributes = @{
                                    NSForegroundColorAttributeName: message.isFromCurrentUser ? userMessageTextColor: accentColor,
                                    NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
                                    };
    
    textView.attributedText = [[NSAttributedString alloc] initWithString:text
                                                              attributes:@{
                                                                           NSFontAttributeName : font,
                                                                           NSForegroundColorAttributeName : textColor,
                                                                           NSParagraphStyleAttributeName: paragraphStyle
                                                                           }];
}

-(NSString*)textForMessage:(id<CLBSOMessage>)message {
    BOOL isSupportedType = [(@[CLBMessageTypeText, CLBMessageTypeFile, CLBMessageTypeImage, CLBMessageTypeLocation, CLBMessageTypeCarousel, CLBMessageTypeList]) containsObject:message.type];
    
    if ([message.type isEqualToString:CLBMessageTypeLocation]) {
        return [CLBLocalization localizedStringForKey:@"Could not send location"];
    } else if (isSupportedType) {
        return message.text;
    } else if (message.textFallback.length > 0) {
        return message.textFallback;
    } else {
        return [CLBLocalization localizedStringForKey:@"Unsupported message type"];
    }
}

-(UITextView*)newTextView {
    return [[self class] newTextViewInternal];
}

+(UITextView*)newTextViewInternal {
    UITextView* textView = [[UITextView alloc] init];

    textView.backgroundColor = [UIColor clearColor];
    [textView setTextContainerInset:UIEdgeInsetsZero];
    textView.textContainer.lineFragmentPadding = 0;
    textView.editable = NO;
    textView.scrollEnabled = NO;
    textView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;

    return textView;
}

@end
