//
//  CLBConversationNavigationItemTitleView.m
//  ClarabridgeChat
//
//  Created by Thaciana Lima on 03/07/2020.
//  Copyright © 2020 Smooch Technologies. All rights reserved.
//

#import "CLBConversationNavigationItemTitleView.h"
#import "CLBUtility.h"

@interface CLBConversationNavigationItemTitleView ()

@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UILabel *descriptionLabel;
@property (nonatomic, weak) UIImageView *avatarImageView;

@property (nonatomic) NSDictionary<NSAttributedStringKey, id> *titleTextAtributtes;

@property (nonatomic) NSLayoutConstraint *avatarWidth;
@property (nonatomic) NSLayoutConstraint *avatarHeight;

@end

@implementation CLBConversationNavigationItemTitleView

- (instancetype)initWithTitleTextAttributes:(NSDictionary<NSAttributedStringKey, id> *)titleTextAttributes {
    self = [super init];
    if (self) {
        _titleTextAtributtes = titleTextAttributes;

        if (CLBIsIOS11OrLater()) {
            self.translatesAutoresizingMaskIntoConstraints = NO;
        } else {
            self.frame = CGRectMake(0, 0, 240, 40);
        }

        // Configure UI
        UIStackView *stackView = UIStackView.new;
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;

        UILabel *displayNameLabel = UILabel.new;
        _titleLabel = displayNameLabel;
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

        UILabel *descriptionLabel = UILabel.new;
        _descriptionLabel = descriptionLabel;
        _descriptionLabel.font = [UIFont systemFontOfSize:12];
        _descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;

        BOOL hasConfiguredColor = [_titleTextAtributtes valueForKey:@"NSColor"] != nil;
        if (!hasConfiguredColor) {
            displayNameLabel.textColor = CLBExtraDarkGrayColor(YES);
            descriptionLabel.textColor = CLBDarkGrayColor(YES);
        }

        UIImageView *avatarImageView = UIImageView.new;
        _avatarImageView = avatarImageView;
        _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarImageView.layer.cornerRadius = 20;
        _avatarImageView.layer.masksToBounds = YES;

        [self addSubview:avatarImageView];
        [self addSubview:stackView];

        [stackView addArrangedSubview:displayNameLabel];
        [stackView addArrangedSubview:descriptionLabel];

        _avatarWidth = [_avatarImageView.widthAnchor constraintEqualToConstant:40];
        _avatarHeight = [_avatarImageView.heightAnchor constraintEqualToConstant:40];

        [NSLayoutConstraint activateConstraints:@[
            _avatarWidth,
            _avatarHeight,
            [_avatarImageView.centerYAnchor constraintEqualToAnchor:avatarImageView.superview.centerYAnchor],
            [_avatarImageView.leftAnchor constraintEqualToAnchor:avatarImageView.superview.leftAnchor],
            [stackView.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:10],
            [stackView.trailingAnchor constraintEqualToAnchor:stackView.superview.trailingAnchor],
            [stackView.centerYAnchor constraintEqualToAnchor:stackView.superview.centerYAnchor],
        ]];

    }
    return self;
}

- (void)configWithTitle:(NSString *)title subtitle:(NSString *)subtitle avatar:(UIImage *)avatar {
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:(title ? title : @"") attributes:self.titleTextAtributtes];
    [self.titleLabel sizeToFit];

    self.descriptionLabel.attributedText = [[NSAttributedString alloc] initWithString:(subtitle ? subtitle : @"") attributes:self.titleTextAtributtes];
    [self.descriptionLabel sizeToFit];

    self.avatarImageView.image = avatar;
}

- (void)updateAvatar:(UIImage *)avatar {
    self.avatarImageView.image = avatar;
}

- (void)adjustAvatarSizeToSize:(NSUInteger)size {
    _avatarWidth.constant = size;
    _avatarHeight.constant = size;
    _avatarImageView.layer.cornerRadius = size / 2;
}

@end
