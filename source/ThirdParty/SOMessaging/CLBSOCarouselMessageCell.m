//
//  CLBSOCarouselMessageCell.m
//  ClarabridgeChat
//
//  Copyright © 2018 Smooch Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLBSOCarouselMessageCell.h"
#import "CLBSOCarouselCollectionViewCell.h"
#import "CLBRoundedRectView.h"
#import "CLBMessageItem.h"
#import "CLBMessageItemViewModel.h"
#import "CLBUtility.h"
#import "CLBLocalization.h"

static const CGFloat kCellLineSpacing = 6;
static const CGFloat kTitleFontSize = 17;
static const CGFloat kDescriptionFontSize = 14;
static const CGFloat kLineSpacing = 1.05;
static const CGFloat kActionsContainerTopPadding = 15;
static const CGFloat kActionButtonHeight = 45;
static const CGFloat kActionButtonSeparatorHeight = 1;
static const CGFloat kActionButtonSeparatorPadding = 11;
static const CGFloat kBorderWidth = 1;
static const CGFloat kBorderArea = kBorderWidth * 2;

@interface CLBSOCarouselMessageCell () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CLBMessageItemViewDelegate>

@property UICollectionView *collectionView;
@property UICollectionViewFlowLayout *collectionViewLayout;
@property CGSize cellSize;
@property NSMutableDictionary *sizeCache;
@property NSMutableDictionary *scrollCache;
@property BOOL shouldOffsetForTimeReveal;

@end

@implementation CLBSOCarouselMessageCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier sizeCache:(NSMutableDictionary *)sizeCache scrollCache:(NSMutableDictionary *)scrollCache {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _sizeCache = sizeCache;
        _scrollCache = scrollCache;
        _collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        _collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionViewLayout.minimumLineSpacing = kCellLineSpacing;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.frame collectionViewLayout:_collectionViewLayout];
        [_collectionView registerClass:[CLBSOCarouselCollectionViewCell class] forCellWithReuseIdentifier:@"carouselCollectionViewCell"];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.bounces = YES;
        _collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        _collectionView.backgroundColor = [UIColor clearColor];
        [self.containerView addSubview:_collectionView];
    }
    
    return self;
}

-(void)adjustCell {
    [super adjustCell];
    
    CGRect frame = self.containerView.frame;
    frame.size.width = self.contentView.frame.size.width;
    frame.origin.x = 0;
    
    CGFloat adjustedUserImageOriginX = self.containerView.frame.origin.x;
    
    // Carousel rows should take full screen width. CLBSOMessageCell adds horizontal padding to self.containerView
    self.containerView.frame = frame;
    
    if (self.showUserImage) {
        CGRect userImageFrame = self.userImageView.frame;
        userImageFrame.origin.x = adjustedUserImageOriginX;
        self.userImageView.frame = userImageFrame;
    }
    
    self.collectionView.frame = CGRectMake(frame.origin.x, 0, frame.size.width, frame.size.height);
    CGFloat scrollLeftInset = adjustedUserImageOriginX + self.viewOriginX; // left edge of first item should align with other type of messages
    CGFloat scrollRightInset = kBubbleRightMargin; // right edge of last item should align with appUser messages
    
    self.collectionView.contentInset = UIEdgeInsetsMake(0, scrollLeftInset, 0, scrollRightInset);
    [self.collectionView reloadData];
    
    CGFloat contentWidth = (self.message.items.count * self.cellSize.width);
    self.shouldOffsetForTimeReveal = self.timeLabel.frame.size.width > frame.size.width - contentWidth;
    
    NSInteger scrollPosition = [[self.scrollCache objectForKey:self.message.messageId] intValue];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:scrollPosition inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    self.userImageView.hidden = scrollPosition != 0 || !self.showUserImage;
}

-(void)layoutContent {
    [super layoutContent];
    
    self.cellSize = [[self.sizeCache objectForKey:self.message.messageId] CGSizeValue];
    
    self.bubbleView.hidden = YES;
    self.bubbleView.frame = CGRectMake(self.viewOriginX, self.contentView.frame.origin.y, 0, self.cellSize.height);
}

-(CGFloat)viewOriginX {
    return kUserImageViewRightMargin + self.userImageViewSize.width + self.contentInsets.left - self.contentInsets.right;
}

-(CGFloat)viewWidth {
    return self.contentView.frame.size.width - self.viewOriginX - kBubbleRightMargin - kBubbleLeftMargin;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.message.items.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CLBSOCarouselCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"carouselCollectionViewCell" forIndexPath:indexPath];
    
    CLBMessageItem *messageItem = self.message.items[indexPath.row];
    CLBMessageItemViewModel *viewModel = [[self class] newMessageItemViewModel];

    BOOL isFirstRow = indexPath.row == 0;
    BOOL isLastRow = indexPath.row == self.message.items.count - 1;
    
    if (isFirstRow) {
        viewModel.flatCorners = isLastRow ? CLBCornerNone : (CLBCornerTopRight | CLBCornerBottomRight);
    } else if (isLastRow) {
        viewModel.flatCorners = CLBCornerTopLeft | CLBCornerBottomLeft;
    } else {
        viewModel.flatCorners = CLBCornerBottomLeft | CLBCornerBottomRight | CLBCornerTopRight | CLBCornerTopLeft;
    }
    
    viewModel.text = messageItem.title;
    viewModel.itemDescription = messageItem.itemDescription;
    viewModel.actions = messageItem.actions;
    viewModel.mediaUrl = messageItem.mediaUrl;
    viewModel.imageViewSize = self.mediaImageViewSize;
    viewModel.messageMaxWidth = self.messageMaxWidth;
    viewModel.preferredContentWidth = self.cellSize.width;
    viewModel.preferredContentHeight = self.cellSize.height;
    viewModel.accentColor = self.accentColor;
    viewModel.actionButtonEnabledColor = self.accentColor;
    
    [cell messageItemView].delegate = self;
    [cell.messageItemView setContent:viewModel];
    [cell.messageItemView loadImage];
    
    return cell;
}

+(CGSize)calculateSizeForMessage:(id<CLBSOMessage>)message withFrame:(CGRect)frame imageSize:(CGSize)imageSize maxWidth:(CGFloat)maxWidth {
    CGSize cellSize = CGSizeZero;
    
    CLBMessageItemView *measurementView = [[CLBMessageItemView alloc] initWithFrame:frame];
    CLBMessageItemViewModel *measurementViewModel = [[self class] newMessageItemViewModel];
    
    BOOL hasImage = NO;
    
    for (CLBMessageItem *messageItem in message.items) {
        if (messageItem.mediaUrl) {
            hasImage = YES;
            break;
        }
    }
    
    CGFloat messageMaxWidth = hasImage ? imageSize.width : maxWidth;
    
    for (CLBMessageItem *messageItem in message.items) {
        measurementViewModel.text = messageItem.title;
        measurementViewModel.itemDescription = messageItem.itemDescription;
        measurementViewModel.actions = messageItem.actions;
        measurementViewModel.mediaUrl = messageItem.mediaUrl;
        measurementViewModel.imageViewSize = imageSize;
        measurementViewModel.messageMaxWidth = messageMaxWidth;
        
        [measurementView setContent:measurementViewModel];
        
        cellSize = CGSizeMake(MAX(measurementView.frame.size.width, cellSize.width), MAX(measurementView.frame.size.height, cellSize.height));
    }
    
    return cellSize;
}

/**
 *  Provides a view model with constant values
 */
+(CLBMessageItemViewModel *)newMessageItemViewModel {
    CLBMessageItemViewModel *viewModel = [[CLBMessageItemViewModel alloc] init];
    
    viewModel.accentColor = [UIColor clearColor];
    viewModel.actionButtonEnabledColor = [UIColor clearColor];
    viewModel.backgroundColor = CLBSystemBackgroundColor();
    viewModel.actionsSeparatorColor = CLBExtraLightGrayColor(YES);
    viewModel.actionButtonFont = [UIFont boldSystemFontOfSize:kTitleFontSize];
    viewModel.actionButtonDisabledColor = CLBMediumGrayColor();
    viewModel.actionButtonHighlightedColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    viewModel.actionsContainerTopPadding = kActionsContainerTopPadding;
    viewModel.actionsButtonHeight = kActionButtonHeight;
    viewModel.actionButtonSeparatorHeight = kActionButtonSeparatorHeight;
    viewModel.actionButtonSeparatorPadding = kActionButtonSeparatorPadding;
    viewModel.actionButtonDisabledText = [CLBLocalization localizedStringForKey:@"Payment Completed"];
    viewModel.actionButtonBackgroundColor = [UIColor clearColor];
    viewModel.titleTextColor = CLBExtraDarkGrayColor(YES);
    viewModel.descriptionTextColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1.0];
    viewModel.titleFontSize = kTitleFontSize;
    viewModel.descriptionFontSize = kDescriptionFontSize;
    viewModel.textLineSpacing = kLineSpacing;
    viewModel.borderWith = kBorderWidth;
    viewModel.borderArea = kBorderArea;
    
    return viewModel;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellSize;
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGFloat cellWidth = self.cellSize.width;
    CGFloat cellPadding = self.collectionViewLayout.minimumLineSpacing;
    
    NSInteger targetItem = [self closestItemToOffset:scrollView.contentOffset withVelocity:velocity cellWidth:cellWidth cellPadding:cellPadding];
    
    CGFloat newOffset = targetItem * (self.cellSize.width + self.collectionViewLayout.minimumLineSpacing) - self.collectionView.contentInset.left;
    targetContentOffset->x = newOffset;
    
    self.userImageView.hidden = targetItem != 0 || !self.showUserImage;
    [self.scrollCache setObject:@(targetItem) forKey:self.message.messageId];
}

-(NSInteger)closestItemToOffset:(CGPoint)offset withVelocity:(CGPoint)velocity cellWidth:(CGFloat)width cellPadding:(CGFloat)padding {
    NSInteger item = (offset.x + ABS(self.collectionView.contentInset.left) - width / 2) / (width + padding) + 1;
    
    if (velocity.x > 0) {
        item++;
    }
    
    if (velocity.x < 0) {
        item--;
    }
    
    return MIN(MAX(item, 0), self.message.items.count - 1);
}

-(BOOL)shouldOffsetFrameForTimeReveal {
    return self.shouldOffsetForTimeReveal;
}

#pragma mark - CLBMessageItemViewDelegate

-(void)messageItemView:(CLBMessageItemView *)view didSelectAction:(CLBMessageAction *)action {
    if ([self.delegate respondsToSelector:@selector(messageCell:didSelectAction:)]) {
        [self.delegate messageCell:self didSelectAction:action];
    }
}

-(void)messageItemView:(CLBMessageItemView *)view didTapImage:(UIImage *)image {
    if ([self.delegate respondsToSelector:@selector(messageCell:didTapImage:onMessageItemView:)]) {
        [self.delegate messageCell:self didTapImage:image onMessageItemView:view];
    }
}

@end
