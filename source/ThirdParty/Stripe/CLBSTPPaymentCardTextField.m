//
//  CLBSTPPaymentCardTextField.m
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CLBSTPPaymentCardTextField.h"
#import "CLBSTPPaymentCardTextFieldViewModel.h"
#import "CLBSTPFormTextField.h"
#import "CLBSTPCardValidator.h"
#import "CLBUtility.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

@interface CLBSTPPaymentCardTextField()<CLBSTPFormTextFieldDelegate>

@property(nonatomic, readwrite, strong)CLBSTPFormTextField *sizingField;

@property(nonatomic, readwrite, weak)UIImageView *brandImageView;
@property(nonatomic, readwrite, weak)UIView *fieldsView;

@property(nonatomic, readwrite, weak)CLBSTPFormTextField *numberField;

@property(nonatomic, readwrite, weak)CLBSTPFormTextField *expirationField;

@property(nonatomic, readwrite, weak)CLBSTPFormTextField *cvcField;

@property(nonatomic, readwrite, strong)CLBSTPPaymentCardTextFieldViewModel *viewModel;

@property(nonatomic, readwrite, weak)UITextField *selectedField;

@property(nonatomic, assign)BOOL numberFieldShrunk;

@end

@implementation CLBSTPPaymentCardTextField

@synthesize font = _font;
@synthesize textColor = _textColor;
@synthesize textErrorColor = _textErrorColor;
@synthesize placeholderColor = _placeholderColor;
@dynamic enabled;

CGFloat const CLBSTPPaymentCardTextFieldDefaultPadding = 10;

#if CGFLOAT_IS_DOUBLE
#define CLBSTP_roundCGFloat(x) round(x)
#else
#define CLBSTP_roundCGFloat(x) roundf(x)
#endif

#pragma mark initializers

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    self.borderColor = [self.class placeholderGrayColor];
    self.cornerRadius = 5.0f;
    self.borderWidth = 1.0f;

    self.clipsToBounds = YES;
    
    _viewModel = [CLBSTPPaymentCardTextFieldViewModel new];
    _sizingField = [self buildTextField];
    
    UIImageView *brandImageView = [[UIImageView alloc] initWithImage:[self brandImageForFieldType:CLBSTPCardFieldTypeNumber]];
    brandImageView.contentMode = UIViewContentModeCenter;
    brandImageView.backgroundColor = [UIColor clearColor];
    if ([brandImageView respondsToSelector:@selector(setTintColor:)]) {
        brandImageView.tintColor = CLBDarkGrayColor(NO);
    }
    self.brandImageView = brandImageView;
    
    CLBSTPFormTextField *numberField = [self buildTextField];
    numberField.formatsCardNumbers = YES;
    numberField.tag = CLBSTPCardFieldTypeNumber;
    self.numberField = numberField;
    self.numberPlaceholder = [self.viewModel defaultPlaceholder];

    CLBSTPFormTextField *expirationField = [self buildTextField];
    expirationField.tag = CLBSTPCardFieldTypeExpiration;
    expirationField.alpha = 0;
    self.expirationField = expirationField;
    self.expirationPlaceholder = @"MM/YY";
        
    CLBSTPFormTextField *cvcField = [self buildTextField];
    cvcField.tag = CLBSTPCardFieldTypeCVC;
    cvcField.alpha = 0;
    self.cvcField = cvcField;
    self.cvcPlaceholder = @"CVC";
    
    UIView *fieldsView = [[UIView alloc] init];
    fieldsView.clipsToBounds = YES;
    fieldsView.backgroundColor = [UIColor clearColor];
    self.fieldsView = fieldsView;
    
    [self addSubview:self.fieldsView];
    [self.fieldsView addSubview:cvcField];
    [self.fieldsView addSubview:expirationField];
    [self.fieldsView addSubview:numberField];
    [self addSubview:brandImageView];
}

- (CLBSTPPaymentCardTextFieldViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [CLBSTPPaymentCardTextFieldViewModel new];
    }
    return _viewModel;
}

#pragma mark appearance properties

+ (UIColor *)placeholderGrayColor {
    return [UIColor lightGrayColor];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:[backgroundColor copy]];
    self.numberField.backgroundColor = self.backgroundColor;
}

- (UIColor *)backgroundColor {
    return [super backgroundColor] ?: [UIColor whiteColor];
}

- (void)setFont:(UIFont *)font {
    _font = [font copy];
    
    for (UITextField *field in [self allFields]) {
        field.font = _font;
    }
    
    self.sizingField.font = _font;
    
    [self setNeedsLayout];
}

- (UIFont *)font {
    return _font ?: [UIFont systemFontOfSize:18];
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = [textColor copy];
    
    for (CLBSTPFormTextField *field in [self allFields]) {
        field.defaultColor = _textColor;
    }
}

- (void)setContentVerticalAlignment:(UIControlContentVerticalAlignment)contentVerticalAlignment {
    [super setContentVerticalAlignment:contentVerticalAlignment];
    for (UITextField *field in [self allFields]) {
        field.contentVerticalAlignment = contentVerticalAlignment;
    }
    switch (contentVerticalAlignment) {
        case UIControlContentVerticalAlignmentCenter:
            self.brandImageView.contentMode = UIViewContentModeCenter;
            break;
        case UIControlContentVerticalAlignmentBottom:
            self.brandImageView.contentMode = UIViewContentModeBottom;
            break;
        case UIControlContentVerticalAlignmentFill:
            self.brandImageView.contentMode = UIViewContentModeTop;
            break;
        case UIControlContentVerticalAlignmentTop:
            self.brandImageView.contentMode = UIViewContentModeTop;
            break;
    }
}

- (UIColor *)textColor {
    return _textColor ?: [UIColor blackColor];
}

- (void)setTextErrorColor:(UIColor *)textErrorColor {
    _textErrorColor = [textErrorColor copy];
    
    for (CLBSTPFormTextField *field in [self allFields]) {
        field.errorColor = _textErrorColor;
    }
}

- (UIColor *)textErrorColor {
    return _textErrorColor ?: [UIColor redColor];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = [placeholderColor copy];
    
    if ([self.brandImageView respondsToSelector:@selector(setTintColor:)]) {
        self.brandImageView.tintColor = CLBDarkGrayColor(NO);
    }
    
    for (CLBSTPFormTextField *field in [self allFields]) {
        field.placeholderColor = _placeholderColor;
    }
}

- (UIColor *)placeholderColor {
    return _placeholderColor ?: [self.class placeholderGrayColor];
}

- (void)setNumberPlaceholder:(NSString * __nullable)numberPlaceholder {
    _numberPlaceholder = [numberPlaceholder copy];
    self.numberField.placeholder = _numberPlaceholder;
}

- (void)setExpirationPlaceholder:(NSString * __nullable)expirationPlaceholder {
    _expirationPlaceholder = [expirationPlaceholder copy];
    self.expirationField.placeholder = _expirationPlaceholder;
}

- (void)setCvcPlaceholder:(NSString * __nullable)cvcPlaceholder {
    _cvcPlaceholder = [cvcPlaceholder copy];
    self.cvcField.placeholder = _cvcPlaceholder;
}

- (void)setCursorColor:(UIColor *)cursorColor {
    self.tintColor = cursorColor;
}

- (UIColor *)cursorColor {
    return self.tintColor;
}

- (void)setBorderColor:(UIColor * __nullable)borderColor {
    self.layer.borderColor = [[borderColor copy] CGColor];
}

- (UIColor * __nullable)borderColor {
    return [[UIColor alloc] initWithCGColor:self.layer.borderColor];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius {
    return self.layer.cornerRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.layer.borderWidth = borderWidth;
}

- (CGFloat)borderWidth {
    return self.layer.borderWidth;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance {
    _keyboardAppearance = keyboardAppearance;
    for (CLBSTPFormTextField *field in [self allFields]) {
        field.keyboardAppearance = keyboardAppearance;
    }
}

- (void)setInputAccessoryView:(UIView *)inputAccessoryView {
    _inputAccessoryView = inputAccessoryView;
    
    for (CLBSTPFormTextField *field in [self allFields]) {
        field.inputAccessoryView = inputAccessoryView;
    }
}

#pragma mark UIControl

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    for (CLBSTPFormTextField *textField in [self allFields]) {
        textField.enabled = enabled;
    };
}

#pragma mark UIResponder & related methods

- (BOOL)isFirstResponder {
    return [self.selectedField isFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return [[self firstResponderField] canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [[self firstResponderField] becomeFirstResponder];
}

- (CLBSTPFormTextField *)firstResponderField {

    if ([self.viewModel validationStateForField:CLBSTPCardFieldTypeNumber] != CLBSTPCardValidationStateValid) {
        return self.numberField;
    } else if ([self.viewModel validationStateForField:CLBSTPCardFieldTypeExpiration] != CLBSTPCardValidationStateValid) {
        return self.expirationField;
    } else {
        return self.cvcField;
    }
}

- (BOOL)canResignFirstResponder {
    return [self.selectedField canResignFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    BOOL success = [self.selectedField resignFirstResponder];
    [self setNumberFieldShrunk:[self shouldShrinkNumberField] animated:YES completion:nil];
    return success;
}

- (BOOL)selectNextField {
    return [[self nextField] becomeFirstResponder];
}

- (BOOL)selectPreviousField {
    return [[self previousField] becomeFirstResponder];
}

- (CLBSTPFormTextField *)nextField {
    if (self.selectedField == self.numberField) {
        return self.expirationField;
    } else if (self.selectedField == self.expirationField) {
        return self.cvcField;
    }
    return nil;
}

- (CLBSTPFormTextField *)previousField {
    if (self.selectedField == self.cvcField) {
        return self.expirationField;
    } else if (self.selectedField == self.expirationField) {
        return self.numberField;
    }
    return nil;
}

#pragma mark public convenience methods

- (void)clear {
    for (CLBSTPFormTextField *field in [self allFields]) {
        field.text = @"";
    }
    self.viewModel = [CLBSTPPaymentCardTextFieldViewModel new];
    [self onChange];
    [self updateImageForFieldType:CLBSTPCardFieldTypeNumber];
    __weak id weakself = self;
    [self setNumberFieldShrunk:NO animated:YES completion:^(__unused BOOL completed){
        __strong id strongself = weakself;
        if ([strongself isFirstResponder]) {
            [[strongself numberField] becomeFirstResponder];
        }
    }];
}

- (BOOL)isValid {
    return [self.viewModel isValid];
}

#pragma mark readonly variables

- (NSString *)cardNumber {
    return self.viewModel.cardNumber;
}

- (NSUInteger)expirationMonth {
    return [self.viewModel.expirationMonth integerValue];
}

- (NSUInteger)expirationYear {
    return [self.viewModel.expirationYear integerValue];
}

- (NSString *)cvc {
    return self.viewModel.cvc;
}

- (CLBSTPCardParams *)card {
    if (!self.isValid) { return nil; }
    
    CLBSTPCardParams *c = [[CLBSTPCardParams alloc] init];
    c.number = self.cardNumber;
    c.expMonth = self.expirationMonth;
    c.expYear = self.expirationYear;
    c.cvc = self.cvc;
    return c;
}

- (CGSize)intrinsicContentSize {
    
    CGSize imageSize = self.viewModel.brandImage.size;
    
    self.sizingField.text = self.viewModel.defaultPlaceholder;
    CGFloat textHeight = [self.sizingField measureTextSize].height;
    CGFloat imageHeight = imageSize.height + (CLBSTPPaymentCardTextFieldDefaultPadding * 2);
    CGFloat height = CLBSTP_roundCGFloat((MAX(MAX(imageHeight, textHeight), 44)));
    
    CGFloat width = CLBSTP_roundCGFloat([self widthForCardNumber:self.viewModel.defaultPlaceholder] + imageSize.width + (CLBSTPPaymentCardTextFieldDefaultPadding * 3));
    
    return CGSizeMake(width, height);
}

- (CGRect)brandImageRectForBounds:(CGRect)bounds {
    return CGRectMake(CLBSTPPaymentCardTextFieldDefaultPadding, 2, self.brandImageView.image.size.width, bounds.size.height - 2);
}

- (CGRect)fieldsRectForBounds:(CGRect)bounds {
    CGRect brandImageRect = [self brandImageRectForBounds:bounds];
    return CGRectMake(CGRectGetMaxX(brandImageRect), 0, CGRectGetWidth(bounds) - CGRectGetMaxX(brandImageRect), CGRectGetHeight(bounds));
}

- (CGRect)numberFieldRectForBounds:(CGRect)bounds {
    return [self numberFieldRectForBounds:bounds text:@"9999 9999 9999 9999"];
}

- (CGRect)numberFieldRectForBounds:(CGRect)bounds text:(NSString*)text {
//    CGFloat placeholderWidth = [self widthForCardNumber:self.numberField.placeholder] - 4;
//    CGFloat numberWidth = [self widthForCardNumber:self.viewModel.defaultPlaceholder] - 4;
//    CGFloat numberFieldWidth = MAX(placeholderWidth, numberWidth);
    CGFloat numberFieldWidth = [self widthForCardNumber:text] - 4;
    CGFloat nonFragmentWidth = [self widthForCardNumber:[self.viewModel numberWithoutLastDigits]] - 8;
    CGFloat numberFieldX = self.numberFieldShrunk ? CLBSTPPaymentCardTextFieldDefaultPadding - nonFragmentWidth : 8;
    return CGRectMake(numberFieldX, 0, numberFieldWidth, CGRectGetHeight(bounds));
}

- (CGRect)cvcFieldRectForBounds:(CGRect)bounds {
    CGRect fieldsRect = [self fieldsRectForBounds:bounds];

    CGFloat cvcWidth = MAX([self widthForText:self.cvcField.placeholder], [self widthForText:@"8888"]);
    CGFloat cvcX = self.numberFieldShrunk ?
    CGRectGetWidth(fieldsRect) - cvcWidth - CLBSTPPaymentCardTextFieldDefaultPadding / 2  :
    CGRectGetWidth(fieldsRect);
    return CGRectMake(cvcX, 0, cvcWidth, CGRectGetHeight(bounds));
}

- (CGRect)expirationFieldRectForBounds:(CGRect)bounds {
    CGRect numberFieldRect = [self numberFieldRectForBounds:bounds];
    CGRect cvcRect = [self cvcFieldRectForBounds:bounds];

    CGFloat expirationWidth = MAX([self widthForText:self.expirationField.placeholder], [self widthForText:@"88/88"]);
    CGFloat expirationX = (CGRectGetMaxX(numberFieldRect) + CGRectGetMinX(cvcRect) - expirationWidth) / 2;
    return CGRectMake(expirationX, 0, expirationWidth, CGRectGetHeight(bounds));
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect bounds = self.bounds;

    self.brandImageView.frame = [self brandImageRectForBounds:bounds];
    self.fieldsView.frame = [self fieldsRectForBounds:bounds];
    self.numberField.frame = [self numberFieldRectForBounds:bounds];
    self.cvcField.frame = [self cvcFieldRectForBounds:bounds];
    self.expirationField.frame = [self expirationFieldRectForBounds:bounds];
    
}

#pragma mark - private helper methods

- (CLBSTPFormTextField *)buildTextField {
    CLBSTPFormTextField *textField = [[CLBSTPFormTextField alloc] initWithFrame:CGRectZero];
    textField.backgroundColor = [UIColor clearColor];
    textField.keyboardType = UIKeyboardTypeNumberPad;
    textField.font = self.font;
    textField.defaultColor = self.textColor;
    textField.errorColor = self.textErrorColor;
    textField.placeholderColor = self.placeholderColor;
    textField.formDelegate = self;
    return textField;
}

- (NSArray *)allFields {
    return @[self.numberField, self.expirationField, self.cvcField];
}

typedef void (^CLBSTPNumberShrunkCompletionBlock)(BOOL completed);
- (void)setNumberFieldShrunk:(BOOL)shrunk animated:(BOOL)animated
                  completion:(CLBSTPNumberShrunkCompletionBlock)completion {
    
    if (_numberFieldShrunk == shrunk) {
        if (completion) {
            completion(YES);
        }
        return;
    }
    
    _numberFieldShrunk = shrunk;
    void (^animations)(void) = ^void() {
        for (UIView *view in @[self.expirationField, self.cvcField]) {
            view.alpha = 1.0f * shrunk;
        }
        [self layoutSubviews];
    };
    
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    NSTimeInterval duration = animated * 0.3;
    if ([UIView respondsToSelector:@selector(animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)]) {
        [UIView animateWithDuration:duration
                              delay:0
             usingSpringWithDamping:0.85f
              initialSpringVelocity:0
                            options:0
                         animations:animations
                         completion:completion];
    } else {
        [UIView animateWithDuration:duration
                         animations:animations
                         completion:completion];
    }
}

- (BOOL)shouldShrinkNumberField {
    return [self.viewModel validationStateForField:CLBSTPCardFieldTypeNumber] == CLBSTPCardValidationStateValid;
}

- (CGFloat)widthForText:(NSString *)text {
    self.sizingField.formatsCardNumbers = NO;
    [self.sizingField setText:text];
    return [self.sizingField measureTextSize].width + 8;
}

- (CGFloat)widthForTextWithLength:(NSUInteger)length {
    NSString *text = [@"" stringByPaddingToLength:length withString:@"M" startingAtIndex:0];
    return [self widthForText:text];
}

- (CGFloat)widthForCardNumber:(NSString *)cardNumber {
    self.sizingField.formatsCardNumbers = YES;
    [self.sizingField setText:cardNumber];
    return [self.sizingField measureTextSize].width + 15;
}

#pragma mark CLBSTPPaymentTextFieldDelegate

- (void)formTextFieldDidBackspaceOnEmpty:(__unused CLBSTPFormTextField *)formTextField {
    CLBSTPFormTextField *previous = [self previousField];
    [previous becomeFirstResponder];
    [previous deleteBackward];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.selectedField = (CLBSTPFormTextField *)textField;
    switch ((CLBSTPCardFieldType)textField.tag) {
        case CLBSTPCardFieldTypeNumber:
            [self setNumberFieldShrunk:NO animated:YES completion:nil];
            break;
            
        default:
            [self setNumberFieldShrunk:YES animated:YES completion:nil];
            break;
    }
    [self updateImageForFieldType:textField.tag];
}

- (void)textFieldDidEndEditing:(__unused UITextField *)textField {
    self.selectedField = nil;
}

- (BOOL)textField:(CLBSTPFormTextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    BOOL deletingLastCharacter = (range.location == textField.text.length - 1 && range.length == 1 && [string isEqualToString:@""]);
    if (deletingLastCharacter && [textField.text hasSuffix:@"/"] && range.location > 0) {
        range.location -= 1;
        range.length += 1;
    }
    
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    CLBSTPCardFieldType fieldType = textField.tag;
    switch (fieldType) {
        case CLBSTPCardFieldTypeNumber:
            self.viewModel.cardNumber = newText;
            textField.text = self.viewModel.cardNumber;
            break;
        case CLBSTPCardFieldTypeExpiration: {
            self.viewModel.rawExpiration = newText;
            textField.text = self.viewModel.rawExpiration;
            break;
        }
        case CLBSTPCardFieldTypeCVC:
            self.viewModel.cvc = newText;
            textField.text = self.viewModel.cvc;
            break;
    }
    
    [self updateImageForFieldType:fieldType];

    CLBSTPCardValidationState state = [self.viewModel validationStateForField:fieldType];
    textField.validText = YES;
    switch (state) {
        case CLBSTPCardValidationStateInvalid:
            textField.validText = NO;
            break;
        case CLBSTPCardValidationStateIncomplete:
            break;
        case CLBSTPCardValidationStateValid: {
            [self selectNextField];
            break;
        }
    }
    [self onChange];

    return NO;
}

- (UIImage *)brandImage {
    if (self.selectedField) {
        return [self brandImageForFieldType:self.selectedField.tag];
    } else {
        return [self brandImageForFieldType:CLBSTPCardFieldTypeNumber];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"
- (UIImage *)cvcImageForCardBrand:(CLBSTPCardBrand)cardBrand {
    return self.viewModel.cvcImage;
}

- (UIImage *)brandImageForCardBrand:(CLBSTPCardBrand)cardBrand {
    return self.viewModel.brandImage;
}
#pragma clang diagnostic pop

- (UIImage *)brandImageForFieldType:(CLBSTPCardFieldType)fieldType {
    if (fieldType == CLBSTPCardFieldTypeCVC) {
        return [self cvcImageForCardBrand:self.viewModel.brand];
    }

    return [self brandImageForCardBrand:self.viewModel.brand];
}

- (void)updateImageForFieldType:(CLBSTPCardFieldType)fieldType {
    UIImage *image = [self brandImageForFieldType:fieldType];
    if (image != self.brandImageView.image) {
        self.brandImageView.image = image;
        
        CATransition *transition = [CATransition animation];
        transition.duration = 0.2f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        
        [self.brandImageView.layer addAnimation:transition forKey:nil];

        [self setNeedsLayout];
    }
}

- (void)onChange {
    if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidChange:)]) {
        [self.delegate paymentCardTextFieldDidChange:self];
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
