//
//  SOMessagingViewController.m
//  SOMessaging
//
// Created by : arturdev
// Copyright (c) 2014 SocialObjects Software. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

#import "CLBSOMessagingViewController.h"
#import "CLBSOMessage.h"
#import "CLBSOMessageCell.h"
#import "CLBSOPhotoMessageCell.h"
#import "CLBSOTextMessageCell.h"
#import "CLBSOVideoMessageCell.h"
#import "CLBSOLocationMessageCell.h"
#import "CLBSOActivityMessageCell.h"
#import "CLBSOCarouselMessageCell.h"
#import "CLBSOFileMessageCell.h"
#import "CLBUtility.h"
#import "ClarabridgeChat+Private.h"
#import "CLBTextViewVendingMachine.h"
#import "CLBImageLoader.h"
#import "CLBRoundedRectView.h"
#import "CLBConversationActivity+Private.h"
#import "CLBLocalization.h"
#import "CLBMessage+Private.h"

typedef NS_ENUM(NSUInteger, CLBSOMessageType) {
    CLBSOMessageTypeUnknown,
    CLBSOMessageTypeMessage,
    CLBSOMessageTypeConversationActivity
};

#define kMessageMaxWidth 240.0f

static NSString* const kInputDisplayedDidChangeNotification = @"CLBInputDisplayedDidChangeNotification";
static BOOL isInputDisplayed = YES;

@interface CLBSOMessagingViewController () <UITableViewDelegate>

@property CLBTextViewVendingMachine* vendingMachine;

@property (strong, nonatomic) UIView *tableViewHeaderView;

@property (strong, nonatomic) NSMutableArray *conversation;
@property UIActivityIndicatorView* loadingSpinner;
@property dispatch_once_t onceToken;

@property NSMutableDictionary *carouselSizeCache;
@property NSMutableDictionary *carouselScrollCache;

@end

static NSDateFormatter* dateFormatter;

@implementation CLBSOMessagingViewController

static NSDateFormatter* dateFormatter;

+(void)setInputDisplayed:(BOOL)displayed {
    isInputDisplayed = displayed;
    [[NSNotificationCenter defaultCenter] postNotificationName:kInputDisplayedDidChangeNotification object:nil];
}

+(BOOL)isInputDisplayed {
    return isInputDisplayed;
}

-(instancetype)initWithAccentColor:(UIColor*)accentColor userMessageTextColor:(UIColor*)userMessageTextColor {
    self = [super init];
    if(self){
        _errorBannerHeight = 0;
        _accentColor = accentColor;
        _userMessageTextColor = userMessageTextColor;
        _vendingMachine = [[CLBTextViewVendingMachine alloc] init];
        _loadStatus = CLBTableViewLoadStatusDelayed;
        _carouselSizeCache = [[NSMutableDictionary alloc] init];
        _carouselScrollCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)setup {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = CLBSystemBackgroundColor();
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.userInteractionEnabled = NO;
    
    if (@available(iOS 11.0, *)) {
        [self.tableView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    }
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    
    self.tableViewHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 10)];
    self.tableViewHeaderView.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = self.tableViewHeaderView;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.tableView];
    
    self.chatInputView = [[CLBSOMessageInputView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 45) viewController:self delegate:self];
    
    if (self.startingText && [self.startingText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
        self.chatInputView.textView.text = self.startingText;
        self.chatInputView.sendButton.enabled = YES;
    }
    
    self.chatInputView.tableView = self.tableView;
    self.chatInputView.userInteractionEnabled = NO;
    self.chatInputView.inputDelegate = self;
    self.chatInputView.displayed = isInputDisplayed;
    
    [self.view addSubview:self.chatInputView];
    
    self.loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:CLBActivityIndicatorViewStyleGray()];
    
    [self.view addSubview:self.loadingSpinner];
}

-(void)inputDisplayedDidChange {
    self.chatInputView.displayed = isInputDisplayed;
}

#pragma mark - View lifecicle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputDisplayedDidChange) name:kInputDisplayedDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.conversation = [self grouppedMessages];
    
    if(self.loadStatus == CLBTableViewLoadStatusDelayed){
        if(self.messages.count > 0){
            [self.loadingSpinner startAnimating];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.loadStatus = CLBTableViewLoadStatusLoading;
                [self.tableView reloadData];
                [self tableViewDidLoad];
            });
        }else{
            self.loadStatus = CLBTableViewLoadStatusLoaded;
            [self.loadingSpinner stopAnimating];
            [self activateTableView];
            [self tableViewDidLoad];
        }
    }else{
        [self.tableView reloadData];
        [self tableViewDidLoad];
        [self scrollToBottom];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.chatInputView reframeAnimated:NO];
    self.loadingSpinner.center = self.view.center;
}

-(void)didReceiveMemoryWarning {
    [self.vendingMachine.cache removeAllObjects];
    [super didReceiveMemoryWarning];
}

- (void)scrollToBottom {
    if (self.tableView.tableFooterView != nil) {
        [self.tableView scrollRectToVisible:[self.tableView convertRect:self.tableView.tableFooterView.bounds fromView:self.tableView.tableFooterView] animated:NO];
    } else if ([self.conversation count]) {
        NSInteger section = self.conversation.count - 1;
        NSInteger row = [self.conversation[section] count] - 1;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        if ( indexPath.row !=-1) {
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
    }
}

-(void)scrollToBottomOnce {
    dispatch_once(&_onceToken, ^{
        [self scrollToBottom];
    });
}

-(void)activateTableView {
    self.tableView.userInteractionEnabled = YES;
    self.chatInputView.userInteractionEnabled = YES;
}

#pragma mark - CLBSOMessageInputViewDelegate

- (void)inputViewDidBeginTyping:(CLBSOMessageInputView *)inputView {}
- (void)inputViewDidFinishTyping:(CLBSOMessageInputView *)inputView {}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(self.loadStatus == CLBTableViewLoadStatusDelayed){
        return 0;
    }else{
        // Return the number of sections.
        return self.conversation.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.loadStatus == CLBTableViewLoadStatusDelayed){
        return 0;
    }else{
        BOOL isLastSection = section == self.conversation.count - 1;
        BOOL hasTypingActivity = [self conversationActivity] != nil;
        
        if (isLastSection && hasTypingActivity) {
            return [self.conversation[section] count] + 1;
        }
        
        // Return the number of rows in the section.
        return [self.conversation[section] count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height;
    
    if ([self isIndexPathForActivityCell:indexPath]) {
        return [self heightForTypingActivityRow];
    }
    
    id<CLBSOMessage> message = self.conversation[indexPath.section][indexPath.row];
    int index = (int)[[self messages] indexOfObjectIdenticalTo:message];
    height = [self heightForMessageForIndex:index];
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)currentIndex {
    if(self.loadStatus == CLBTableViewLoadStatusLoaded){
        BOOL isTopRow = currentIndex.section == 0 && currentIndex.row == 0;
        if(isTopRow && self.tableView.contentSize.height > self.view.bounds.size.height) {
            [self didReachTopOfMessages];
        }
        return;
    }
    
    if(self.loadStatus == CLBTableViewLoadStatusLoading && currentIndex.row == 0 && currentIndex.section == 0){
        self.loadStatus = CLBTableViewLoadStatusLoaded;
        
        [self scrollToBottomOnce];
        [self activateTableView];
        [self tableViewDidLoad];
        [self.loadingSpinner stopAnimating];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    id<CLBSOMessage> firstMessageInGroup = [self.conversation[section] firstObject];
    NSDate *date = [firstMessageInGroup date];
    
    if(!dateFormatter){
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[CLBLocalization localizedStringForKey:@"MMMM d, h:mm a"]];
    }
    
    UILabel *label = [[UILabel alloc] init];
    label.text = [[dateFormatter stringFromDate:date] uppercaseString];
    label.textColor = CLBMediumGrayColor();
    label.font = [UIFont systemFontOfSize:12];
    label.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 40);
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.backgroundColor = [UIColor clearColor];
    
    return label;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier;
    
    CLBSOMessageCell *cell;
    
    NSObject<CLBSOMessage>* message;
    
    Class class;
    
    BOOL isActivityCell = [self isIndexPathForActivityCell:indexPath];
    
    if (isActivityCell) {
        cellIdentifier = @"activityCell";
        class = [CLBSOActivityMessageCell class];
        message = [self conversationActivity];
    } else {
        message = self.conversation[indexPath.section][indexPath.row];
        
        if ([message.type isEqualToString:CLBMessageTypeImage]){
            cellIdentifier = @"photoCell";
            class = [CLBSOPhotoMessageCell class];
        } else if ([message.type isEqualToString:CLBMessageTypeLocation]) {
            CLBMessage* locationMessage = (CLBMessage*)message;
            
            if (message.failed && ![locationMessage hasCoordinates]) {
                cellIdentifier = @"textCell";
                class = [CLBSOTextMessageCell class];
            } else {
                cellIdentifier = @"locationCell";
                class = [CLBSOLocationMessageCell class];
            }
        } else if ([self isCarouselMessage:message]) {
            cellIdentifier = @"carouselCell";
            class = [CLBSOCarouselMessageCell class];
        } else if ([message.type isEqualToString:CLBMessageTypeFile]) {
            cellIdentifier = @"fileCell";
            class = [CLBSOFileMessageCell class];
        } else {
            cellIdentifier = @"textCell";
            class = [CLBSOTextMessageCell class];
        }
    }

    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        if([class instancesRespondToSelector:@selector(initWithStyle:reuseIdentifier:vendingMachine:)]){
            cell = [[class alloc] initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:cellIdentifier
                                 vendingMachine:self.vendingMachine];
        }else if([class instancesRespondToSelector:@selector(initWithStyle:reuseIdentifier:sizeCache:scrollCache:)]){
            cell = [[class alloc] initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:cellIdentifier
                                      sizeCache:self.carouselSizeCache
                                    scrollCache:self.carouselScrollCache];
        }else{
            cell = [[class alloc] initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:cellIdentifier];
        }
        
        cell.tableView = self.tableView;
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accentColor = self.accentColor;
        cell.userMessageTextColor = self.userMessageTextColor;
    }
    
    cell.mediaImageViewSize = [self mediaThumbnailSizeForMessage:message];
    cell.messageMaxWidth = [self messageMaxWidthForMessage:message];
    
    cell.bubbleColor = [self bubbleColorForMessage:message];
    
    cell.message = message;
    
    cell.hidden = [self shouldHideCellForMessage:message];
    
    // For user customization
    int index = (int)[[self messages] indexOfObjectIdenticalTo:message];
    cell.showName = isActivityCell ? [self shouldShowNameForTypingActivity] : [self shouldIndexShowName:index];
    cell.showUserImage = isActivityCell ?: [self shouldIndexShowUserImage:index];
    cell.bubbleTopMargin = isActivityCell ? [self topMarginForTypingActivity] : [self topMarginForIndex:index];
    cell.showStatus = isActivityCell ? NO : [self shouldShowStatus:index];
    
    [self configureMessageCell:cell forMessageAtIndex:index];
    
    cell.bubbleView.flatCorners = [self cornersForMessage:message atIndexPath:indexPath];
    
    return cell;
}

-(CLBCorners)cornersForMessage:(NSObject<CLBSOMessage>*)message atIndexPath:(NSIndexPath*)indexPath {
    BOOL isTypingActivityMessage = [self isIndexPathForActivityCell:indexPath];
    
    CLBCorners flatCorners = CLBCornerNone;
    
    int index = (int)[[self messages] indexOfObjectIdenticalTo:message];
    
    NSObject<CLBSOMessage>* previousMessage = indexPath.row > 0 ? self.conversation[indexPath.section][indexPath.row - 1] : nil;
    BOOL isPreviousMessageHidden = previousMessage && [self shouldHideCellForMessage:previousMessage];
    
    BOOL shouldShowName = isTypingActivityMessage ? [self shouldShowNameForTypingActivity] : [self shouldIndexShowName:index];
    if(previousMessage && !isPreviousMessageHidden && (previousMessage.isFromCurrentUser == message.isFromCurrentUser && !shouldShowName)){
        if(message.isFromCurrentUser){
            flatCorners = flatCorners | CLBCornerTopRight;
        }else if (![self isCarouselMessage:previousMessage]){
            flatCorners = flatCorners | CLBCornerTopLeft;
        }
    }
    
    NSObject<CLBSOMessage>* nextMessage;
    
    BOOL hasTypingActivity = [self conversationActivity] != nil;
    
    BOOL nextMessageIsTypingActivityMessage = [self isIndexPathForLastSection:indexPath] && [self isIndexPathForLastRow:indexPath] && hasTypingActivity;
    
    BOOL nextMessageShouldShowName;
    BOOL isNextMessageHidden = NO;
    
    if (nextMessageIsTypingActivityMessage) {
        nextMessage = [self conversationActivity];
        nextMessageShouldShowName = [self shouldShowNameForTypingActivity];
    } else {
        nextMessage = indexPath.row < [self.conversation[indexPath.section] count] - 1 ? self.conversation[indexPath.section][indexPath.row + 1] : nil;
        nextMessageShouldShowName = [self shouldIndexShowName:index + 1];
        isNextMessageHidden = [self shouldHideCellForMessage:nextMessage];
    }
    
    if(nextMessage && !isNextMessageHidden && (nextMessage.isFromCurrentUser == message.isFromCurrentUser && !nextMessageShouldShowName)){
        if(message.isFromCurrentUser){
            flatCorners = flatCorners | CLBCornerBottomRight;
        }else if (![self isCarouselMessage:nextMessage]){
            flatCorners = flatCorners | CLBCornerBottomLeft;
        }
    }
    
    return flatCorners;
}

-(BOOL)isIndexPathForActivityCell:(NSIndexPath *)indexPath {
    BOOL isLastSection = [self isIndexPathForLastSection:indexPath];
    BOOL isActivityRow = indexPath.row == [self.conversation[indexPath.section] count];
    return [self conversationActivity] && isLastSection && isActivityRow;
}

-(BOOL)isIndexPathForLastSection:(NSIndexPath *)indexPath {
    return indexPath.section == self.conversation.count - 1;
}

-(BOOL)isIndexPathForLastRow:(NSIndexPath *)indexPath {
    return indexPath.row == [self.conversation[indexPath.section] count] - 1;
}

-(BOOL)shouldHideCellForMessage:(NSObject<CLBSOMessage> *)message {
    if ([message isKindOfClass:[CLBConversationActivity class]]) {
        return NO;
    }
    
    BOOL isText = [message.type isEqualToString:CLBMessageTypeText];
    BOOL isEmptyText = !message.text || [message.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0;
    BOOL hasReplyOrLocationRequestActions = NO;
    
    for (CLBMessageAction *action in message.actions) {
        if ([CLBMessageActionTypeReply isEqualToString:action.type] || [CLBMessageActionTypeLocationRequest isEqualToString:action.type]) {
            hasReplyOrLocationRequestActions = YES;
            break;
        }
    }
    
    return isText && isEmptyText && hasReplyOrLocationRequestActions;
}

#pragma mark - SOMessaging datasource
- (NSMutableArray *)messages {
    return nil;
}

- (CLBConversationActivity *)conversationActivity {
    return nil;
}

- (CGFloat)heightForMessageForIndex:(NSInteger)index {
    if (index < 0 || index >= self.messages.count) {
        return 0;
    }

    NSObject<CLBSOMessage>* message = [self messages][index];
    
    if ([self shouldHideCellForMessage:message]) {
        return 0;
    }
    
    CGFloat height = 0;
    CGFloat topMargin = [self topMarginForIndex:index];
    CGFloat bottomMargin = [self bottomMarginForIndex:index];
    CGSize userImageSize = kAvatarSize;
    
    BOOL isImage = [message.type isEqualToString:CLBMessageTypeImage];
    BOOL isFile = [message.type isEqualToString:CLBMessageTypeFile];
    BOOL isCarousel = [self isCarouselMessage:message];
    
    CLBMessage* locationMessage = (CLBMessage*)message;
    BOOL shouldShowMap = [message.type isEqualToString:CLBMessageTypeLocation] && ([locationMessage hasCoordinates] || !message.failed);
    
    if (isImage || shouldShowMap) {
        CGSize size = [self mediaThumbnailSizeForMessage:message];
        if (size.height < userImageSize.height) {
            size.height = userImageSize.height;
        }
        
        height = size.height;
    }
    
    if (isCarousel) {
        if (![self.carouselSizeCache objectForKey:message.messageId]) {
            CGSize carouselSize = [CLBSOCarouselMessageCell calculateSizeForMessage:message withFrame:CGRectZero imageSize:[self mediaThumbnailSizeForMessage:message] maxWidth:[self messageMaxWidthForMessage:message]];
            [self.carouselSizeCache setObject:[NSValue valueWithCGSize:carouselSize] forKey:message.messageId];
        }
        height += [[self.carouselSizeCache objectForKey:message.messageId] CGSizeValue].height;
    } else if (isFile) {
        height += [CLBSOFileMessageCell heightForMessage:message withVendingMachine:self.vendingMachine maxWidth:[self messageMaxWidthForMessage:message]];
    } else if(!shouldShowMap) {
        NSString* text = [self.vendingMachine textForMessage:message];
        NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        CGFloat messageMaxWidth = [self messageMaxWidthForMessage:message];
        if (trimmedText.length > 0) {
            height += [self.vendingMachine sizeForMessage:message constrainedToWidth:messageMaxWidth].height;
            UIEdgeInsets textViewPadding = CLBSOMessageCellTextViewPadding;
            height += textViewPadding.top + textViewPadding.bottom;
        }
        
        height += [CLBSOTextMessageCell extraHeightForMessage:message withWidth:messageMaxWidth];
    }
    
    if (message.failed || !message.sent || [self shouldShowStatus:index]){
        height += 20;
    }
        
    if (!message.isFromCurrentUser && height < userImageSize.height) {
        height = userImageSize.height;
    }
    
    height += topMargin + bottomMargin;
    
    return height;
}

-(CGFloat)heightForTypingActivityRow {
    return kAvatarSize.height + [self topMarginForTypingActivity] + kBubbleBottomMargin;
}

- (BOOL)isSameUserInFirstSOMessage:(id<CLBSOMessage>)first
                andSecondSOMessage:(id<CLBSOMessage>)second
                           forType:(CLBSOMessageType)type {

    BOOL sameName = [self isValidIsEqual:first.displayName secondValue:second.displayName];
    BOOL sameAvatar = [self valuesAreEqual:first.avatarUrl secondValue:second.avatarUrl];

    switch (type) {
        case CLBSOMessageTypeMessage: {
            BOOL sameUserId = [self isValidIsEqual:first.userId secondValue:second.userId];
            return sameUserId && sameName && sameAvatar;
            break;
        }
        case CLBSOMessageTypeConversationActivity: {
            BOOL sameUserId = [self isValidIsEqual:first.userId secondValue:second.userId];
            return sameUserId && sameName && sameAvatar;
            break;
        }
        default:
            return sameName && sameAvatar;
            break;
    }
}

- (BOOL)isValidIsEqual:(NSString *)firstValue secondValue:(NSString *)secondValue {
    BOOL hasValue = firstValue != nil && ![firstValue isEqualToString:@""];
    BOOL sameValue = [firstValue isEqualToString:secondValue];
    return hasValue && sameValue;
}

- (BOOL)valuesAreEqual:(NSString *)firstValue secondValue:(NSString *)secondValue {
    if (firstValue == nil && secondValue == nil) {
        return YES;
    }

    return [firstValue isEqualToString:secondValue];
}

-(BOOL)shouldShowNameForTypingActivity {
    id<CLBSOMessage> conversationActivity = [self conversationActivity];
    
    if (!conversationActivity) {
        return NO;
    }
    
    id<CLBSOMessage> lastMessage = [self.messages lastObject];

    BOOL isSameUser = [self isSameUserInFirstSOMessage:conversationActivity
                                    andSecondSOMessage:lastMessage
                                               forType:CLBSOMessageTypeConversationActivity];

    return lastMessage.isFromCurrentUser || !isSameUser;
}

-(BOOL)shouldIndexShowName:(NSInteger)index {
    if(index < 0 || index >= self.messages.count){
        return NO;
    }
    
    id<CLBSOMessage> currentMessage = self.messages[index];
    if(index == 0){
        return !currentMessage.isFromCurrentUser;
    }else{
        id<CLBSOMessage> previousMessage = self.messages[index - 1];

        BOOL sameCurrentUser = previousMessage.isFromCurrentUser == currentMessage.isFromCurrentUser;
        BOOL firstRemoteMessage = currentMessage.isFromCurrentUser && !previousMessage.isFromCurrentUser;
        BOOL isSameUser = [self isSameUserInFirstSOMessage:currentMessage
                                        andSecondSOMessage:previousMessage
                                                   forType:CLBSOMessageTypeMessage];

        if(!currentMessage.isFromCurrentUser && ( firstRemoteMessage || !isSameUser || !sameCurrentUser )){
            return YES;
        }
    }
    return NO;
}

-(BOOL)shouldIndexShowUserImage:(NSInteger)index {
    if (index < 0 || index >= self.messages.count){
        return NO;
    }
    
    id<CLBSOMessage> currentMessage = self.messages[index];
    
    if (currentMessage.isFromCurrentUser) {
        return NO;
    }
    
    if (index == self.messages.count - 1) {
        id<CLBSOMessage> conversationActivity = [self conversationActivity];
        
        if (conversationActivity) {
            BOOL isSameUser = [self isSameUserInFirstSOMessage:conversationActivity
                                            andSecondSOMessage:currentMessage
                                                       forType:CLBSOMessageTypeConversationActivity];
            return !isSameUser;
        }
        
        return YES;
    }
    
    NSObject<CLBSOMessage> *nextMessage = self.messages[index + 1];
    
    if (nextMessage.isFromCurrentUser) {
        return YES;
    }
    
    if ([self shouldHideCellForMessage:nextMessage]) {
        return YES;
    }

    BOOL isSameUser = [self isSameUserInFirstSOMessage:nextMessage
                                    andSecondSOMessage:currentMessage
                                               forType:CLBSOMessageTypeMessage];
    return !isSameUser;
}

-(BOOL)shouldShowStatus:(NSInteger)index {
    if (index < 0 || index >= self.messages.count){
        return NO;
    }
    
    id<CLBSOMessage> currentMessage = self.messages[index];
    
    if (!currentMessage.isFromCurrentUser && [self conversationActivity]) {
        return NO;
    }
    
    return index == self.messages.count - 1;
}

-(CGFloat)topMarginForTypingActivity {
    if ([self shouldShowNameForTypingActivity]) {
        return 23;
    }
    
    id<CLBSOMessage> lastMessage = [self.messages lastObject];
    
    return lastMessage.isFromCurrentUser ? 10 : 0;
}

-(CGFloat)topMarginForIndex:(NSInteger)index {
    if([self shouldIndexShowName:index]){
        //Give a new thread of incoming message a larger margin to fit the name label.
        if(index == 0){
            return 17;
        }else{
            return 23;
        }
    }
    
    if(index > 0 && index < self.messages.count){
        id<CLBSOMessage> prevMessage = self.messages[index - 1];
        id<CLBSOMessage> currentMessage = self.messages[index];
        
        if(prevMessage.isFromCurrentUser != currentMessage.isFromCurrentUser){
            return 10;
        }
    }
    
    return 0;
}

-(CGFloat)bottomMarginForIndex:(NSInteger)index {
    return kBubbleBottomMargin;
}

- (UIColor *)desaturateColor:(UIColor*)color {
    CGFloat hue, saturation, brightness, alpha;
    [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    if(saturation > 0.4){
        saturation = 0.4;
    }
    
    UIColor* desaturatedColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
    return desaturatedColor;
}

- (void)didReachTopOfMessages {
    
}

- (void)tableViewDidLoad {
    
}

- (void)configureMessageCell:(CLBSOMessageCell *)cell forMessageAtIndex:(NSInteger)index {
    
}

-(BOOL)isCarouselMessage:(id<CLBSOMessage>)message {
    return [message.type isEqualToString:CLBMessageTypeCarousel] || [message.type isEqualToString:CLBMessageTypeList];
}

-(UIColor *)bubbleColorForMessage:(id<CLBSOMessage>)message {
    
    if (message.isFromCurrentUser){
        if ((message.sent || [message.type isEqualToString:CLBMessageTypeFile]) && !message.failed){
            return self.accentColor;
        } else {
            return [self desaturateColor:self.accentColor];
        }
    }
    
    return CLBExtraLightGrayColor(YES);
}

- (CGFloat)messageMaxWidthForMessage:(id<CLBSOMessage>) message {
    if ([message.type isEqualToString:CLBMessageTypeImage]) {
        return [self mediaThumbnailSizeForMessage:message].width;
    }
    
    if ([self isCarouselMessage:message]) {
        return [self mediaThumbnailSizeForMessage:message].width;
    }
    
    CGFloat portraitWidth = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
    
    if(CLBIsIpad()){
        return portraitWidth * 0.6;
    }else{
        return portraitWidth - 130;
    }
}

- (CGSize)mediaThumbnailSizeForMessage:(id<CLBSOMessage>) message {
    CGFloat width = 240;
    CGFloat height = 160;
    
    if ([self isCarouselMessage:message] && [message.imageAspectRatio isEqualToString:CLBImageAspectRatioSquare]) {
        return CGSizeMake(width, width);
    }
    
    return CGSizeMake(width, height);
}

#pragma mark - Public methods

- (void)refreshMessages {
    [self refreshMessagesAndKeepOffset:NO];
}

-(void)refreshMessagesAndKeepOffset:(BOOL)keepOffset {
    [self refreshMessagesAndKeepOffset:keepOffset animateScrollToBottom:YES];
}

-(void)refreshMessagesAndKeepOffset:(BOOL)keepOffset animateScrollToBottom:(BOOL)animateScroll {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    
    CGFloat previousHeight = self.tableView.contentSize.height;
    CGPoint offset = self.tableView.contentOffset;
    
    self.conversation = [self grouppedMessages];
    [self.tableView reloadData];
    
    [UIView commitAnimations];
    
    if(keepOffset) {
        CGFloat newHeight = self.tableView.contentSize.height;
        if(newHeight > self.view.bounds.size.height) {
            self.tableView.contentOffset = CGPointMake(0, newHeight - previousHeight + offset.y);
        }
        return;
    }

    [self scrollToBottom];
}

#pragma mark - Private methods
- (NSMutableArray *)grouppedMessages {
    NSMutableArray *conversation = [NSMutableArray new];
    
    int groupIndex = 0;
    NSMutableArray *allMessages = [self messages];
    
    for (int i = 0; i < allMessages.count; i++) {
        if (i == 0) {
            NSMutableArray *firstGroup = [NSMutableArray new];
            [firstGroup addObject:allMessages[i]];
            [conversation addObject:firstGroup];
        } else {
            id<CLBSOMessage> prevMessage    = allMessages[i-1];
            id<CLBSOMessage> currentMessage = allMessages[i];
            
            NSDate *prevMessageDate    = prevMessage.date;
            NSDate *currentMessageDate = currentMessage.date;
            
            if ([[NSCalendar currentCalendar] isDate:prevMessageDate inSameDayAsDate:currentMessageDate]) {
                NSMutableArray *group = conversation[groupIndex];
                [group addObject:currentMessage];
                
            } else {
                NSMutableArray *newGroup = [NSMutableArray new];
                [newGroup addObject:currentMessage];
                [conversation addObject:newGroup];
                groupIndex++;
            }
        }
    }
    
    return conversation;
}

#pragma mark - Helper methods
- (UIImage *)tintImage:(UIImage *)image withColor:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextClipToMask(context, rect, image.CGImage);
    [color setFill];
    CGContextFillRect(context, rect);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self refreshMessagesAndKeepOffset:YES];
}

@end
