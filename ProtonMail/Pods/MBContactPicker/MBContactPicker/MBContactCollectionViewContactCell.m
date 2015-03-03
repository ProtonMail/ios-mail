//
//  ContactCollectionViewCell.m
//  MBContactPicker
//
//  Created by Matt Bowman on 11/20/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import "MBContactCollectionViewContactCell.h"

@interface MBContactCollectionViewContactCell()

@property (nonatomic, weak) UILabel *contactTitleLabel;

@end

@implementation MBContactCollectionViewContactCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup
{
    UILabel *contactLabel = [[UILabel alloc] initWithFrame:self.bounds];
    [self addSubview:contactLabel];
    contactLabel.textColor = [UIColor blueColor];
    contactLabel.textAlignment = NSTextAlignmentCenter;
    contactLabel.clipsToBounds = YES;
    UIFont *font = [[self.class appearance] font];
    if (font)
    {
        contactLabel.font = font;
    }
    contactLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.contactTitleLabel = contactLabel;

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(2)-[contactLabel]-(2)-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(contactLabel)]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contactLabel]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(contactLabel)]];
}

- (void)tintColorDidChange{
    self.focused = self.focused;
}

- (void)setModel:(id<MBContactPickerModelProtocol>)model
{
    _model = model;
    self.contactTitleLabel.text = self.model.contactTitle;
}

- (CGFloat)widthForCellWithContact:(id<MBContactPickerModelProtocol>)model
{
    UIFont *font = self.contactTitleLabel.font;
    CGSize size = [model.contactTitle boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:0 attributes:@{ NSFontAttributeName: font } context:nil].size;
    return ceilf(size.width) + 10;
}

- (void)setFocused:(BOOL)focused
{
    _focused = focused;
    
    if (focused)
    {
        self.contactTitleLabel.textColor = [UIColor whiteColor];
        self.contactTitleLabel.backgroundColor = self.tintColor;
        self.contactTitleLabel.layer.cornerRadius = 3.0f;
    }
    else
    {
        self.contactTitleLabel.textColor = self.tintColor;
        self.contactTitleLabel.backgroundColor = [UIColor clearColor];
    }
}

@end
