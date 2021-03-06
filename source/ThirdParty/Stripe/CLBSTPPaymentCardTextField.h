//
//  CLBSTPPaymentCardTextField.h
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CLBSTPCard.h"

extern CGFloat const CLBSTPPaymentCardTextFieldDefaultPadding;

@class CLBSTPPaymentCardTextField;

/**
 *  This protocol allows a delegate to be notified when a payment text field's contents change, which can in turn be used to take further actions depending on the validity of its contents.
 */
@protocol CLBSTPPaymentCardTextFieldDelegate <NSObject>
@optional
/**
 *  Called when either the card number, expiration, or CVC changes. At this point, one can call -isValid on the text field to determine, for example, whether or not to enable a button to submit the form. Example:
 
 - (void)paymentCardTextFieldDidChange:(CLBSTPPaymentCardTextField *)textField {
      self.paymentButton.enabled = textField.isValid;
 }
 
 *
 *  @param textField the text field that has changed
 */
- (void)paymentCardTextFieldDidChange:(nonnull CLBSTPPaymentCardTextField *)textField;

@end


/**
 *  CLBSTPPaymentCardTextField is a text field with similar properties to UITextField, but specialized for collecting credit/debit card information. It manages multiple UITextFields under the hood to collect this information. It's designed to fit on a single line, and from a design perspective can be used anywhere a UITextField would be appropriate.
 */
@interface CLBSTPPaymentCardTextField : UIControl

/**
 *  @see CLBSTPPaymentCardTextFieldDelegate
 */
@property(nonatomic, weak, nullable) IBOutlet id<CLBSTPPaymentCardTextFieldDelegate> delegate;

/**
 *  The font used in each child field. Default is [UIFont systemFontOfSize:18]. Set this property to nil to reset to the default.
 */
@property(nonatomic, copy, null_resettable) UIFont *font UI_APPEARANCE_SELECTOR;

/**
 *  The text color to be used when entering valid text. Default is [UIColor blackColor]. Set this property to nil to reset to the default.
 */
@property(nonatomic, copy, null_resettable) IBInspectable UIColor *textColor UI_APPEARANCE_SELECTOR;

/**
 *  The text color to be used when the user has entered invalid information, such as an invalid card number. Default is [UIColor redColor]. Set this property to nil to reset to the default.
 */
@property(nonatomic, copy, null_resettable) IBInspectable UIColor *textErrorColor UI_APPEARANCE_SELECTOR IBInspectable;

/**
 *  The text placeholder color used in each child field. Default is [UIColor lightGreyColor]. Set this property to nil to reset to the default. On iOS 7 and above, this will also set the color of the card placeholder icon.
 */
@property(nonatomic, copy, null_resettable) IBInspectable UIColor *placeholderColor UI_APPEARANCE_SELECTOR IBInspectable;

/**
 *  The placeholder for the card number field. Default is @"1234567812345678". If this is set to something that resembles a card number, it will automatically format it as such (in other words, you don't need to add spaces to this string).
 */
@property(nonatomic, copy, nullable) NSString *numberPlaceholder;

/**
 *  The placeholder for the expiration field. Defaults to @"MM/YY".
 */
@property(nonatomic, copy, nullable) NSString *expirationPlaceholder;

/**
 *  The placeholder for the cvc field. Defaults to @"CVC".
 */
@property(nonatomic, copy, nullable) NSString *cvcPlaceholder;

/**
 *  The cursor color for the field. This is a proxy for the view's tintColor property, exposed for clarity only (in other words, calling setCursorColor is identical to calling setTintColor).
 */
@property(nonatomic, copy, null_resettable) UIColor *cursorColor UI_APPEARANCE_SELECTOR;

/**
 *  The border color for the field. Default is [UIColor lightGreyColor]. Can be nil (in which case no border will be drawn).
 */
@property(nonatomic, copy, nullable) IBInspectable UIColor *borderColor UI_APPEARANCE_SELECTOR;

/**
 *  The width of the field's border. Default is 1.0.
 */
@property(nonatomic, assign) IBInspectable CGFloat borderWidth UI_APPEARANCE_SELECTOR;

/**
 *  The corner radius for the field's border. Default is 5.0.
 */
@property(nonatomic, assign) IBInspectable CGFloat cornerRadius UI_APPEARANCE_SELECTOR;

/**
 *  The keyboard appearance for the field. Default is UIKeyboardAppearanceDefault.
 */
@property(nonatomic, assign) IBInspectable UIKeyboardAppearance keyboardAppearance UI_APPEARANCE_SELECTOR;

/**
 *  This behaves identically to setting the inputAccessoryView for each child text field.
 */
@property(nonatomic, strong, nullable) UIView *inputAccessoryView;

/**
 *  The curent brand image displayed in the receiver.
 */
@property (nonatomic, readonly, nullable) UIImage *brandImage;

/**
 *  Causes the text field to begin editing. Presents the keyboard.
 *
 *  @return Whether or not the text field successfully began editing.
 *  @see UIResponder
 */
- (BOOL)becomeFirstResponder;

/**
 *  Causes the text field to stop editing. Dismisses the keyboard.
 *
 *  @return Whether or not the field successfully stopped editing.
 *  @see UIResponder
 */
- (BOOL)resignFirstResponder;

/**
 *  Resets all of the contents of all of the fields. If the field is currently being edited, the number field will become selected.
 */
- (void)clear;

/**
 *  Returns the cvc image used for a card brand.
 *  @param cardBrand The brand of card entered.
 *  @return The cvc image for used for a card brand.
 */
- (nullable UIImage *)cvcImageForCardBrand:(CLBSTPCardBrand)cardBrand;

/**
 *  Returns the brand image used for a card brand.
 *  @param cardBrand The brand of card entered.
 *  @return The brand image for used for a card brand.
 */
- (nullable UIImage *)brandImageForCardBrand:(CLBSTPCardBrand)cardBrand;

/**
 *  Returns the rectangle in which the receiver draws its brand image.
 *  @param bounds The bounding rectangle of the receiver.
 *  @return the rectangle in which the receiver draws its brand image.
 */
- (CGRect)brandImageRectForBounds:(CGRect)bounds;

/**
 *  Returns the rectangle in which the receiver draws the text fields.
 *  @param bounds The bounding rectangle of the receiver.
 *  @return The rectangle in which the receiver draws the text fields.
 */
- (CGRect)fieldsRectForBounds:(CGRect)bounds;

/**
 *  Returns the rectangle in which the receiver draws its number field.
 *  @param bounds The bounding rectangle of the receiver.
 *  @return the rectangle in which the receiver draws its number field.
 */
- (CGRect)numberFieldRectForBounds:(CGRect)bounds;
- (CGRect)numberFieldRectForBounds:(CGRect)bounds text:(nonnull NSString*)text;

/**
 *  Returns the rectangle in which the receiver draws its cvc field.
 *  @param bounds The bounding rectangle of the receiver.
 *  @return the rectangle in which the receiver draws its cvc field.
 */
- (CGRect)cvcFieldRectForBounds:(CGRect)bounds;

/**
 *  Returns the rectangle in which the receiver draws its expiration field.
 *  @param bounds The bounding rectangle of the receiver.
 *  @return the rectangle in which the receiver draws its expiration field.
 */
- (CGRect)expirationFieldRectForBounds:(CGRect)bounds;

/**
 *  Whether or not the form currently contains a valid card number, expiration date, and CVC.
 *  @see CLBSTPCardValidator
 */
@property(nonatomic, readonly, getter=isValid)BOOL valid;

/**
 *  Enable/disable selecting or editing the field. Useful when submitting card details to Stripe.
 */
@property(nonatomic, getter=isEnabled) BOOL enabled;

/**
 *  The current card number displayed by the field. May or may not be valid, unless isValid is true, in which case it is guaranteed to be valid.
 */
@property(nonatomic, readonly, nullable) NSString *cardNumber;

/**
 *  The current expiration month displayed by the field (1 = January, etc). May or may not be valid, unless isValid is true, in which case it is guaranteed to be valid.
 */
@property(nonatomic, readonly) NSUInteger expirationMonth;

/**
 *  The current expiration year displayed by the field, modulo 100 (e.g. the year 2015 will be represented as 15). May or may not be valid, unless isValid is true, in which case it is guaranteed to be valid.
 */
@property(nonatomic, readonly) NSUInteger expirationYear;

/**
 *  The current card CVC displayed by the field. May or may not be valid, unless isValid is true, in which case it is guaranteed to be valid.
 */
@property(nonatomic, readonly, nullable) NSString *cvc;

/**
 *  Convenience method to create a CLBSTPCard from the currently entered information. Will return nil if not valid.
 */
@property(nonatomic, readonly, nullable) CLBSTPCardParams *card;

@end
