//
//  CLBConversationListTableViewCell.m
//  ClarabridgeChat
//
//  Created by Conor Nolan on 20/05/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBConversationListTableViewCell.h"
#import "CLBUtility.h"
#import "ClarabridgeChat+Private.h"

@interface CLBConversationListTableViewCell()

@property(nonatomic) UIImageView *avatarImageView;
@property(nonatomic) UILabel *displayNameLabel;
@property(nonatomic) UILabel *timeUpdatedLabel;
@property(nonatomic) UILabel *lastMessageLabel;
@property(nonatomic) UILabel *badgeLabel;
@property(nonatomic) UIStackView *mainStackView;
@property(nonatomic) UIStackView *titleStackView;
@property(nonatomic) UIStackView *bottomStackView;
@property(nonatomic) UIStackView *messageStackView;
@property(nonatomic) UIView *badgeView;
@property(nonatomic) NSLayoutConstraint *badgeWidth;
@property(nonatomic) CLBConversationViewModel *viewModel;
@property(nonatomic) CLBImageLoader *imageLoader;

@end

@implementation CLBConversationListTableViewCell

static NSString * _Nonnull const _cellIdentifier = @"CLBConversationListTableViewCell";

+ (NSString *)cellIdentifier {
    return _cellIdentifier;
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) return nil;

    [self.contentView.heightAnchor constraintGreaterThanOrEqualToConstant:76].active = YES;

    // Display Name
    _displayNameLabel = [[UILabel alloc] init];
    _displayNameLabel.textColor = CLBLabelColor();
    _displayNameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    _displayNameLabel.numberOfLines = 1;
    [_displayNameLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];

    // Time Updated
    _timeUpdatedLabel = [[UILabel alloc] init];
    _timeUpdatedLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    _timeUpdatedLabel.numberOfLines = 1;
    _timeUpdatedLabel.textColor = CLBSecondaryLabelColor();
    [_timeUpdatedLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    // Last Message
    _lastMessageLabel = [[UILabel alloc] init];
    _lastMessageLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    _lastMessageLabel.textColor = CLBLabelColor();
    _lastMessageLabel.numberOfLines = 2;
    _lastMessageLabel.lineBreakMode = NSLineBreakByWordWrapping;

    // Avatar
    _avatarImageView = [[UIImageView alloc] init];
    _avatarImageView.layer.cornerRadius = 20;
    _avatarImageView.layer.masksToBounds = YES;

    // Unread Badge View
    _badgeView = [[UIView alloc] init];
    _badgeView.backgroundColor = UIColor.systemBlueColor;
    _badgeView.layer.cornerRadius = 8;
    _badgeView.layer.masksToBounds = YES;
    [_badgeView setHidden:true];
    [_badgeView setTranslatesAutoresizingMaskIntoConstraints:NO];

    // Unread Badge Label
    _badgeLabel = [[UILabel alloc] init];
    _badgeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    _badgeLabel.textColor = UIColor.whiteColor;
    _badgeLabel.textAlignment = NSTextAlignmentCenter;
    _badgeLabel.numberOfLines = 1;
    [_badgeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_badgeView addSubview:_badgeLabel];

    // Main Stack View
    _mainStackView = [[UIStackView alloc] init];
    _mainStackView.axis = UILayoutConstraintAxisHorizontal;
    _mainStackView.distribution = UIStackViewDistributionFill;
    _mainStackView.alignment = UIStackViewAlignmentCenter;
    _mainStackView.spacing = 16;
    [_mainStackView setTranslatesAutoresizingMaskIntoConstraints:NO];

    // Message Stack View
    _messageStackView = [[UIStackView alloc] init];
    _messageStackView.axis = UILayoutConstraintAxisVertical;
    _messageStackView.distribution = UIStackViewDistributionFill;
    _messageStackView.alignment = UIStackViewAlignmentFill;
    _messageStackView.spacing = 4;
    [_messageStackView setTranslatesAutoresizingMaskIntoConstraints:NO];

    //Title Stack View
    _titleStackView = [[UIStackView alloc] init];
    _titleStackView.axis = UILayoutConstraintAxisHorizontal;
    _titleStackView.distribution = UIStackViewDistributionFill;
    _titleStackView.alignment = UIStackViewAlignmentCenter;
    _titleStackView.spacing = 6;
    [_titleStackView setTranslatesAutoresizingMaskIntoConstraints:NO];

    //Bottom Stack View
    _bottomStackView = [[UIStackView alloc] init];
    _bottomStackView.axis = UILayoutConstraintAxisHorizontal;
    _bottomStackView.distribution = UIStackViewDistributionFill;
    _bottomStackView.alignment = UIStackViewAlignmentTop;
    _bottomStackView.spacing = 12;
    [_bottomStackView setTranslatesAutoresizingMaskIntoConstraints:NO];

    // Add Components to Stack Views
    [_mainStackView addArrangedSubview:_avatarImageView];
    [_mainStackView addArrangedSubview:_messageStackView];

    [_messageStackView addArrangedSubview:_titleStackView];
    [_messageStackView addArrangedSubview:_bottomStackView];

    [_titleStackView addArrangedSubview:_displayNameLabel];
    [_titleStackView addArrangedSubview:_timeUpdatedLabel];

    [_bottomStackView addArrangedSubview:_lastMessageLabel];
    [_bottomStackView addArrangedSubview:_badgeView];

    [self.contentView addSubview:_mainStackView];

    // Layout for Stack View
    [_mainStackView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
    [_mainStackView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;

    // Main Stack Anchors
    [_mainStackView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16].active = YES;
    [_mainStackView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16].active = YES;

    // Avatar Anchors
    [_avatarImageView.heightAnchor constraintEqualToConstant:40].active = YES;
    [_avatarImageView.widthAnchor constraintEqualToConstant:40].active = YES;

    // Unread Badge Anchors
    [_badgeView.heightAnchor constraintEqualToConstant:16].active = YES;
    [_badgeLabel.centerYAnchor constraintEqualToAnchor:_badgeLabel.superview.centerYAnchor].active = YES;
    [_badgeLabel.centerXAnchor constraintEqualToAnchor:_badgeLabel.superview.centerXAnchor].active = YES;
    _badgeWidth = [_badgeView.widthAnchor constraintEqualToConstant:16];
    _badgeWidth.active = YES;

    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.imageLoader cancelRequestForURL:self.viewModel.avatarURLString];
    [self.badgeView setHidden:true];
    [self.viewModel stopTemporalUpdates];
    self.lastMessageLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
}

- (void)configureWithConversationViewModel:(CLBConversationViewModel *)viewModel {
    self.viewModel = viewModel;
    self.imageLoader = viewModel.imageLoader;

    __weak CLBConversationListTableViewCell *weakSelf = self;
    __weak CLBConversationViewModel *weakViewModel = viewModel;
    viewModel.avatarChangedBlock = ^(UIImage *image) {
        // If cell has not been recycled
        if (weakViewModel == weakSelf.viewModel) {
            weakSelf.avatarImageView.image = image;
        }
    };
    viewModel.formattedLastUpdatedChangedBlock = ^{
        // If cell has not been recycled
        if (weakViewModel == weakSelf.viewModel) {
            weakSelf.timeUpdatedLabel.text = weakViewModel.formattedLastUpdated;
        }
    };

    self.displayNameLabel.text = viewModel.displayName;
    self.timeUpdatedLabel.text = viewModel.formattedLastUpdated;

    [self loadAvatar];
    
    if (viewModel.lastMessage && viewModel.lastMessage.length > 0) {
        NSMutableAttributedString *attributedLastMessage = [[NSMutableAttributedString alloc] initWithString:viewModel.lastMessage];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:5];
        [attributedLastMessage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [viewModel.lastMessage length])];
        self.lastMessageLabel.attributedText = attributedLastMessage;
        self.lastMessageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }

    if (viewModel.unreadCount > 0) {
        self.badgeLabel.text = viewModel.formattedUnreadCount;
        [self.badgeView setHidden:false];
        [self.badgeLabel sizeToFit];
        // Set the width of the badge view to always be 8 points larger than the label to account for padding.
        self.badgeWidth.constant = MAX(16,self.badgeLabel.frame.size.width + 8);
        self.lastMessageLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    }

    [viewModel startTemporalUpdates];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Retain blue background color of the badge on select. (Required in iOS 12 and below).
    self.badgeView.backgroundColor = UIColor.systemBlueColor;
}

- (void)loadAvatar {
    if (!self.viewModel || !self.imageLoader) return;

    self.avatarImageView.image = [ClarabridgeChat getImageFromResourceBundle:@"defaultAvatar"];
    [self.viewModel loadAvatarWithImageLoader:self.imageLoader];
}

@end
