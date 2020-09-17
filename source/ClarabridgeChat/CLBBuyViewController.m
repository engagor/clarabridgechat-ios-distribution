//
//  CLBBuyViewController.m
//  ClarabridgeChat
//
//  Copyright © 2015 Radialpoint. All rights reserved.
//

#import "CLBBuyViewController.h"
#import "CLBUtility.h"
#import "CLBMessageAction.h"
#import "CLBPaymentTextField.h"
#import "CLBStripeApiClient.h"
#import "CLBLocalization.h"
#import "CLBProgressButton.h"
#import "CLBUITextField+Shake.h"
#import "CLBUser+Private.h"
#import "ClarabridgeChat+Private.h"

static const CGFloat kButtonBottomMargin = 15;
static const CGFloat kDefaultVerticalMargin = 10;
static const CGFloat kPaymentTextFieldHeight = 45;

@interface CLBBuyViewController () < CLBSTPPaymentCardTextFieldDelegate >

@property UIView* containerView;
@property UIView* backgroundView;
@property CLBPaymentTextField* paymentTextField;
@property UILabel* moneyLabel;
@property UILabel* instructionLabel;
@property UINavigationBar* navBar;
@property UIBarButtonItem* cancelButton;
@property CLBProgressButton* buyButton;
@property CGFloat keyboardHeight;
@property BOOL isRotating;
@property BOOL isSavedCreditCardMode;
@property UIButton* changeCardButton;
@property UIView* darkenView;
@property UIActivityIndicatorView* loadingSpinner;

@end

@implementation CLBBuyViewController

+(UIFont*)thinFontWithSize:(CGFloat)size {
    return [UIFont systemFontOfSize:size weight:UIFontWeightThin];
}

+(UIFont*)lightFontWithSize:(CGFloat)size {
    return [UIFont systemFontOfSize:size weight:UIFontWeightLight];
}

-(instancetype)initWithAction:(CLBMessageAction*)action user:(CLBUser*)user apiClient:(CLBStripeApiClient*)apiClient {
    self = [super init];
    if (self) {
        _user = user;
        _action = action;
        _apiClient = apiClient;
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.containerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.containerView];

    self.view.backgroundColor = [UIColor clearColor];

    self.backgroundView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:CLBBlurEffectStyle()]];
    [self.containerView addSubview:self.backgroundView];

    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:[CLBLocalization localizedStringForKey:@"Cancel"] style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];

    self.navBar = [[UINavigationBar alloc] init];
    UINavigationItem* navItem = [[UINavigationItem alloc] initWithTitle:@""];
    navItem.leftBarButtonItem = self.cancelButton;
    [self.navBar pushNavigationItem:navItem animated:NO];
    [self.navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navBar setShadowImage:[UIImage new]];
    self.navBar.translucent = YES;
    self.navBar.tintColor = self.accentColor;
    [self.containerView addSubview:self.navBar];

    self.moneyLabel = [[UILabel alloc] init];
    self.moneyLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:self.moneyLabel];

    self.instructionLabel = [[UILabel alloc] init];
    self.instructionLabel.font = [UIFont systemFontOfSize:13];
    self.instructionLabel.numberOfLines = 3;
    [self.containerView addSubview:self.instructionLabel];

    self.paymentTextField = [[CLBPaymentTextField alloc] init];
    self.paymentTextField.font = [[self class] lightFontWithSize:24];
    self.paymentTextField.cursorColor = self.accentColor;
    self.paymentTextField.borderColor = [UIColor clearColor];
    self.paymentTextField.textColor = CLBExtraDarkGrayColor(YES);
    self.paymentTextField.placeholderColor = [CLBMediumGrayColor() colorWithAlphaComponent:0.5];
    self.paymentTextField.delegate = self;
    [self.containerView addSubview:self.paymentTextField];

    self.buyButton = [[CLBProgressButton alloc] init];
    self.buyButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [self.buyButton setTitle:[CLBLocalization localizedStringForKey:@"Pay Now"] forState:UIControlStateNormal];
    [self.buyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.buyButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.6] forState:UIControlStateHighlighted];
    self.buyButton.backgroundColor = self.accentColor;
    [self.buyButton addTarget:self action:@selector(onBuyTapped) forControlEvents:UIControlEventTouchUpInside];
    self.buyButton.shown = NO;
    self.buyButton.alpha = 0.0;

    self.buyButton.shrinkOnProcessing = YES;
    [self.containerView addSubview:self.buyButton];

    if(self.user.hasPaymentInfo){
        [self setupSavedCreditCardUI];
    }

    [self setInstructionLabelDefaultText];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

-(void)setupSavedCreditCardUI {
    self.isSavedCreditCardMode = YES;

    self.changeCardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.changeCardButton setTitleColor:self.accentColor forState:UIControlStateNormal];
    [self.changeCardButton setTitle:[CLBLocalization localizedStringForKey:@"Change Credit Card"] forState:UIControlStateNormal];
    [self.changeCardButton sizeToFit];
    [self.changeCardButton addTarget:self action:@selector(changeCreditCard) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.changeCardButton];

    self.darkenView = [[UIView alloc] init];
    self.darkenView.backgroundColor = [UIColor blackColor];
    self.darkenView.alpha = 0.0;
    [self.view addSubview:self.darkenView];
    [self.view sendSubviewToBack:self.darkenView];

    self.buyButton.shown = YES;

    self.paymentTextField.placeholderColor = CLBExtraDarkGrayColor(YES);
    self.paymentTextField.enabled = NO;

    if(self.user.cardInfo){
        [self handleCardInfo:self.user.cardInfo];
    }else{
        [self fetchCardInfo];
    }
}

-(void)fetchCardInfo {
    NSArray* views = @[self.changeCardButton, self.paymentTextField, self.instructionLabel, self.moneyLabel, self.buyButton];
    [views setValue:@YES forKey:@"hidden"];

    self.loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:CLBActivityIndicatorViewStyleGray()];
    self.loadingSpinner.transform = CGAffineTransformMakeScale(2.0, 2.0);
    [self.containerView addSubview:self.loadingSpinner];
    [self.loadingSpinner startAnimating];

    [self.apiClient getCardInfoForUser:self.user completion:^(NSDictionary *cardInfo) {
        CLBEnsureMainThread(^{
            [views setValue:@NO forKey:@"hidden"];

            [self.loadingSpinner stopAnimating];
            [self.loadingSpinner removeFromSuperview];
            self.loadingSpinner = nil;

            if(cardInfo){
                self.user.cardInfo = cardInfo;
                [self handleCardInfo:cardInfo];
            }else{
                [self changeCreditCard];
            }
        });
    }];
}

-(void)handleCardInfo:(NSDictionary*)cardInfo {
    self.paymentTextField.numberPlaceholder = [NSString stringWithFormat:@"•••• •••• •••• %@", cardInfo[@"last4"]];
    self.paymentTextField.brandImageOverride = [self.paymentTextField brandImageFromString:cardInfo[@"brand"]];
}

-(void)changeCreditCard {
    self.isSavedCreditCardMode = NO;

    [self setInstructionLabelDefaultText];

    self.buyButton.alpha = 0.0;
    self.buyButton.shown = NO;

    self.paymentTextField.numberPlaceholder = @"1234567812345678";
    self.paymentTextField.placeholderColor = [CLBMediumGrayColor() colorWithAlphaComponent:0.5];
    self.paymentTextField.brandImageOverride = nil;
    self.paymentTextField.enabled = YES;
    [self.paymentTextField becomeFirstResponder];

    [self.changeCardButton removeFromSuperview];
    self.changeCardButton = nil;

    self.instructionLabel.alpha = 0.0;

    [UIView animateWithDuration:0.15 delay:0.1 options:0 animations:^{
        self.instructionLabel.alpha = 1.0;
    } completion:nil];

    [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
        [self doLayout];

        self.darkenView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.darkenView removeFromSuperview];
        self.darkenView = nil;
    }];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.paymentTextField becomeFirstResponder];

    if(self.isBeingPresented){
        [self layoutButton];

        if(self.isSavedCreditCardMode){
            self.darkenView.frame = self.view.bounds;
            self.containerView.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height);
        }
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if(self.isBeingPresented && self.isSavedCreditCardMode){
        [UIView animateWithDuration:0.15 animations:^{
            self.darkenView.alpha = 0.5;
        }];

        [UIView animateWithDuration:0.3 animations:^{
            self.containerView.transform = CGAffineTransformIdentity;

            BOOL isPortrait = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
            CGFloat coeffecient = isPortrait ? 0.4 : 0.2;
            CGFloat yOrigin = self.view.bounds.size.height * coeffecient;

            self.darkenView.frame = CGRectMake(0, 0, self.view.bounds.size.width, yOrigin);
        }];
    }
}

-(void)dismissWithPurchase:(BOOL)didPurchase {
    if(self.isSavedCreditCardMode){
        [UIView animateWithDuration:0.15 animations:^{
            self.darkenView.alpha = 0.0;
        }];

        [UIView animateWithDuration:0.3 animations:^{
            self.containerView.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height);
            self.darkenView.frame = self.view.bounds;
        } completion:^(BOOL finished) {
            [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];

            if(didPurchase && [self.delegate respondsToSelector:@selector(buyViewControllerDidDismissWithPurchase:)]){
                [self.delegate buyViewControllerDidDismissWithPurchase:self];
            }
        }];
    }else{
        [self dismissViewControllerAnimated:YES completion:^{
            if(didPurchase && [self.delegate respondsToSelector:@selector(buyViewControllerDidDismissWithPurchase:)]){
                [self.delegate buyViewControllerDidDismissWithPurchase:self];
            }
        }];
    }
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [self doLayout];
}

-(void)doLayout {
    if(self.isSavedCreditCardMode){
        BOOL isPortrait = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
        CGFloat coeffecient = isPortrait ? 0.4 : 0.2;
        CGFloat yOrigin = self.view.bounds.size.height * coeffecient;

        self.navBar.frame = CGRectMake(0, yOrigin - CLBStatusBarHeight(), self.view.bounds.size.width, CLBNavBarHeight());
        self.backgroundView.frame = CGRectMake(0, yOrigin, self.view.bounds.size.width, self.view.bounds.size.height - yOrigin);

        if(self.isRotating){
            self.darkenView.frame = CGRectMake(0, 0, self.view.bounds.size.width, yOrigin);
        }
    }else{
        self.navBar.frame = CGRectMake(0, CLBSafeBoundsForView(self.view).origin.y, self.view.bounds.size.width, CLBNavBarHeight());
        self.backgroundView.frame = self.view.bounds;
    }

    self.loadingSpinner.center = CGPointMake(CGRectGetMidX(self.backgroundView.frame), CGRectGetMidY(self.backgroundView.frame));

    // Order matters
    [self layoutHeader];
    [self layoutPaymentTextField];
    [self layoutChangeCardButton];
    if(self.isRotating){
        [self layoutButton];
    }
    [self layoutInstructionLabel];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.isRotating = YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    self.isRotating = NO;
}

-(CGFloat)ccFieldWidth {
    CGRect maxRect = CGRectMake(0, 0, CGFLOAT_MAX, kPaymentTextFieldHeight);

    CGRect numberRect;
    if(self.isSavedCreditCardMode){
        numberRect = [self.paymentTextField numberFieldRectForBounds:maxRect text:self.paymentTextField.numberPlaceholder];
    }else{
        numberRect = [self.paymentTextField numberFieldRectForBounds:maxRect];
    }

    CGRect ccIconRect = [self.paymentTextField brandImageRectForBounds:maxRect];
    return CGRectGetWidth(numberRect) + CGRectGetMaxX(ccIconRect) + CLBSTPPaymentCardTextFieldDefaultPadding;
}

-(CGFloat)widthForLabelAndButton {
    return MIN([self ccFieldWidth], self.view.bounds.size.width * 0.8);
}

-(void)layoutHeader {
    BOOL isExtraWideScreen = CLBIsExtraWideScreenDevice();

    CGFloat moneyLabelFontSize = 83.5;
    CGFloat moneyLabelSuperscriptSize = 41;
    CGFloat moneyLabelSuperscriptOffset = 28;
    CGFloat moneyLabelHeight = 65;

    if((CLBIsLayoutPhoneInLandscape() && !isExtraWideScreen) || !CLBIsTallScreenDevice()){
        moneyLabelFontSize = 40;
        moneyLabelSuperscriptSize = 20;
        moneyLabelSuperscriptOffset = 13;
        moneyLabelHeight = 30;
    }

    self.moneyLabel.font = [[self class] thinFontWithSize:moneyLabelFontSize];

    BOOL isRoundNumber = self.action.amount % 100 == 0;

    NSString* amountString = [NSString stringWithFormat:@"$%@", [self amountString]];
    if(!isRoundNumber){
        amountString = [amountString stringByReplacingOccurrencesOfString:@"." withString:@""];
    }
    NSMutableAttributedString* str = [[NSMutableAttributedString alloc] initWithString:amountString];

    NSDictionary* superscriptAttributes = @{
                                            NSFontAttributeName : [[self class] lightFontWithSize:moneyLabelSuperscriptSize],
                                            NSBaselineOffsetAttributeName : @(moneyLabelSuperscriptOffset)
                                            };

    [str setAttributes:superscriptAttributes range:NSMakeRange(0, 1)];

    if(!isRoundNumber){
        [str setAttributes:superscriptAttributes range:NSMakeRange(str.length - 2, 2)];
    }

    self.moneyLabel.attributedText = str;

    BOOL isIpad = CLBIsIpad();
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);

    CGFloat moneyLabelYOrigin;
    if(self.isSavedCreditCardMode || isPortrait){
        if(isIpad && isPortrait){
            moneyLabelYOrigin = self.view.bounds.size.height * 0.3;
        }else{
            moneyLabelYOrigin = CGRectGetMaxY(self.navBar.frame) - 10;
        }
    }else{
        moneyLabelYOrigin = CLBStatusBarHeight() + kDefaultVerticalMargin;
    }

    self.moneyLabel.frame = CGRectMake(0, moneyLabelYOrigin, self.view.bounds.size.width, moneyLabelHeight);
}

-(void)layoutPaymentTextField {
    self.paymentTextField.frame = CGRectMake(0,
                                             CGRectGetMaxY(self.moneyLabel.frame) + kDefaultVerticalMargin,
                                             [self ccFieldWidth],
                                             kPaymentTextFieldHeight);
    self.paymentTextField.center = CGPointMake(self.view.bounds.size.width / 2, self.paymentTextField.center.y);
}

-(void)layoutChangeCardButton {
    self.changeCardButton.center = CGPointMake(self.view.bounds.size.width / 2,
                                               CGRectGetMaxY(self.paymentTextField.frame) + self.changeCardButton.frame.size.height / 2);
}

-(void)layoutInstructionLabel {
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    CGFloat width = isPortrait ? [self widthForLabelAndButton] : self.view.bounds.size.width * 0.9;

    CGFloat height = [self.instructionLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
    CGFloat yOrigin = CGRectGetMaxY(self.paymentTextField.frame) + kDefaultVerticalMargin;

    if(self.isSavedCreditCardMode) {
        yOrigin = self.buyButton.frame.origin.y - height - kDefaultVerticalMargin;
    }

    self.instructionLabel.frame = CGRectMake(0,
                                             yOrigin,
                                             width,
                                             height);

    self.instructionLabel.center = CGPointMake(self.view.bounds.size.width / 2, self.instructionLabel.center.y);
}

-(void)layoutButton {
    CGAffineTransform transform = self.buyButton.transform;
    self.buyButton.transform = CGAffineTransformIdentity;

    CGSize buttonSize = [self buyButtonSize];
    CGRect frame = {{0,0}, buttonSize};

    if(CLBIsLayoutPhoneInLandscape() && !CLBIsWideScreenDevice() && !self.isSavedCreditCardMode){
        CGFloat buttonRightMargin = 10;

        frame.origin.x = self.view.bounds.size.width - buttonSize.width - buttonRightMargin;
        frame.origin.y = CLBStatusBarHeight() + kDefaultVerticalMargin;

        self.buyButton.frame = frame;
    }else{
        frame.origin.x = 0;
        frame.origin.y = self.view.bounds.size.height - self.keyboardHeight - buttonSize.height - kButtonBottomMargin;

        self.buyButton.frame = frame;
        self.buyButton.center = CGPointMake(self.view.bounds.size.width / 2, self.buyButton.center.y);
    }

    self.buyButton.layer.cornerRadius = buttonSize.height / 2;
    self.buyButton.transform = transform;
}

-(void)keyboardWillShow:(NSNotification*)notification {
    self.keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;

    [self layoutButton];
}

-(CGSize)buyButtonSize {
    CGFloat buyButtonHeight = 44;
    if(CLBIsLayoutPhoneInLandscape() && !CLBIsWideScreenDevice() && !self.isSavedCreditCardMode){
        CGSize buttonSize = [self.buyButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, buyButtonHeight)];
        CGFloat buttonPadding = 20;
        buyButtonHeight = 30;

        return CGSizeMake(buttonSize.width + buttonPadding, buyButtonHeight);
    }else{
        return CGSizeMake([self widthForLabelAndButton], buyButtonHeight);
    }
}

-(NSString*)amountString {
    long dollars = self.action.amount / 100;
    long cents = self.action.amount % 100;
    BOOL isRoundNumber = cents == 0;

    if(isRoundNumber){
         return [NSString stringWithFormat:@"%ld", dollars];
    }else if(cents < 10){
        return [NSString stringWithFormat:@"%ld.0%ld", dollars, cents];
    }else{
        return [NSString stringWithFormat:@"%ld.%ld", dollars, cents];
    }
}

-(void)paymentCardTextFieldDidChange:(CLBSTPPaymentCardTextField *)textField {
    if(self.isSavedCreditCardMode){
        return;
    }

    if(textField.isValid){
        self.buyButton.shown = YES;
    }else{
        self.buyButton.shown = NO;
    }
    [self setInstructionLabelDefaultText];
}

-(NSParagraphStyle*)paragraphStyleForInstructionLabel {
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 2;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    return paragraphStyle;
}

-(void)setInstructionLabelDefaultText {
    NSString* currency = [self.action.currency uppercaseString];
    NSDictionary* darkTextAttributes = @{ NSForegroundColorAttributeName: CLBExtraDarkGrayColor(YES) };

    NSDictionary* defaultTextAttributes = @{
                                            NSForegroundColorAttributeName: CLBDarkGrayColor(NO),
                                            NSParagraphStyleAttributeName: [self paragraphStyleForInstructionLabel]
                                            };

    NSString* text;
    if(self.isSavedCreditCardMode){
        text = [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"You're about to send $%@ %@ securely to %@"], [self amountString], currency, CLBGetAppDisplayName()];
    }else{
        text = [NSString stringWithFormat:[CLBLocalization localizedStringForKey:@"Enter your credit card to send $%@ %@ securely to %@"], [self amountString], currency, CLBGetAppDisplayName()];
    }

    NSRange priceRange = [text rangeOfString:[NSString stringWithFormat:@"$%@ %@", [self amountString], currency]];

    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:text attributes:defaultTextAttributes];
    [attrString setAttributes:darkTextAttributes range:priceRange];

    self.instructionLabel.attributedText = attrString;

    [self layoutInstructionLabel];
}

-(void)showError {
    CLBEnsureMainThread(^{
        NSString* text = [CLBLocalization localizedStringForKey:@"An error occurred while processing the card. Try again or use a different card."];

        self.instructionLabel.attributedText = [[NSAttributedString alloc] initWithString:text
                                                                               attributes:@{
                                                                                            NSForegroundColorAttributeName: CLBRedColor(),
                                                                                            NSParagraphStyleAttributeName: [self paragraphStyleForInstructionLabel]
                                                                                            }];

        [self.buyButton resetToWidth:[self buyButtonSize].width];
        self.buyButton.enabled = YES;
        self.cancelButton.enabled = YES;

        [CLBUITextFieldShake shake:6 withDelta:10 completion:nil view:self.paymentTextField];

        [self layoutInstructionLabel];
    });
}

-(void)cancel {
    [self dismissWithPurchase:NO];
}

-(void)showSuccessAndDismiss {
    CLBEnsureMainThread(^{
        [self.buyButton setCompleted];
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Unsubscribe from keyboard notifs - Fixes a sizing glitch with the pay button
        [[NSNotificationCenter defaultCenter] removeObserver:self];

        [self dismissWithPurchase:YES];
    });
}

-(void)onBuyTapped {
    [self setInstructionLabelDefaultText];

    self.buyButton.enabled = NO;
    [self.buyButton setProcessing:YES];
    self.cancelButton.enabled = NO;

    void (^finalCompletion)(NSError* error) = ^(NSError *error) {
        if(error){
            [self showError];
        }else{
            [self showSuccessAndDismiss];
        }
    };

    if([self isUserLoggedIn]){
        if(self.isSavedCreditCardMode){
            [self.apiClient chargeUser:self.user forAction:self.action withToken:nil completion:finalCompletion];
        }else{
            [self.apiClient getStripeToken:self.paymentTextField.card completion:^(NSString *token) {
                if(token){
                    [self.apiClient createCustomerForUser:self.user withToken:token completion:^(NSError *error) {
                        if(error){
                            [self showError];
                        }else{
                            self.user.hasPaymentInfo = YES;
                            self.user.cardInfo = nil;
                            [self.apiClient chargeUser:self.user forAction:self.action withToken:nil completion:finalCompletion];
                        }
                    }];
                }else{
                    [self showError];
                }
            }];
        }
    }else{
        [self.apiClient getStripeToken:self.paymentTextField.card completion:^(NSString *token) {
            if(token){
                [self.apiClient chargeUser:self.user forAction:self.action withToken:token completion:finalCompletion];
            }else{
                [self showError];
            }
        }];
    }
}

-(BOOL)isUserLoggedIn {
    return [ClarabridgeChat isUserLoggedIn];
}

@end
