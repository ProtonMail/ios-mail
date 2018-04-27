//
//  ContactCollectionViewContactCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/27/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

//
//@interface MBContactCollectionViewContactCell : UICollectionViewCell
//
//@property (nonatomic, strong) id<MBContactPickerModelProtocol> model;
//@property (nonatomic) BOOL pickerFocused;
//@property (nonatomic, strong) UIFont *font UI_APPEARANCE_SELECTOR;
//
//- (CGFloat)widthForCellWithContact:(id<MBContactPickerModelProtocol>)model;
//
//@end
//


class ContactCollectionViewContactCell: UICollectionViewCell {
    
}


//
//
//#define UIColorFromRGB(rgbValue) [UIColor \
//colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
//green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
//blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
//
//@interface MBContactCollectionViewContactCell()
//
//@property (nonatomic, weak) UILabel *contactTitleLabel;
//
//@end
//
//@implementation MBContactCollectionViewContactCell
//
//- (instancetype)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        [self setup];
//    }
//    return self;
//    }
//    
//    - (instancetype)initWithCoder:(NSCoder *)aDecoder
//{
//    self = [super initWithCoder:aDecoder];
//    if (self) {
//        [self setup];
//    }
//    return self;
//    }
//    
//    - (void)awakeFromNib
//        {
//            [super awakeFromNib];
//            [self setup];
//        }
//        
//        - (void)setup
//            {
//                self.backgroundColor = UIColorFromRGB(0xFCFEFF);
//                
//                UILabel *contactLabel = [[UILabel alloc] initWithFrame:self.bounds];
//                [self addSubview:contactLabel];
//                contactLabel.textColor = [UIColor blueColor];
//                contactLabel.textAlignment = NSTextAlignmentCenter;
//                contactLabel.clipsToBounds = YES;
//                contactLabel.layer.cornerRadius = 3.0;
//                //contactLabel.layer.borderColor = UIColorFromRGB(0x6789AB).CGColor;
//                //contactLabel.layer.borderWidth = 1.0;
//                
//                UIFont *font = [[self.class appearance] font];
//                if (font)
//                {
//                    contactLabel.font = font;
//                }
//                contactLabel.translatesAutoresizingMaskIntoConstraints = NO;
//                self.contactTitleLabel = contactLabel;
//                
//                [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(2)-[contactLabel]-(2)-|"
//                    options:0
//                    metrics:nil
//                    views:NSDictionaryOfVariableBindings(contactLabel)]];
//                
//                [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(8)-[contactLabel]-(8)-|"
//                    options:0
//                    metrics:nil
//                    views:NSDictionaryOfVariableBindings(contactLabel)]];
//            }
//            
//            - (void)tintColorDidChange{
//                self.pickerFocused = self.pickerFocused;
//                }
//                
//                - (void)setModel:(id<MBContactPickerModelProtocol>)model
//{
//    _model = model;
//    self.contactTitleLabel.text = self.model.contactTitle;
//    }
//    
//    - (CGFloat)widthForCellWithContact:(id<MBContactPickerModelProtocol>)model
//{
//    UIFont *font = self.contactTitleLabel.font;
//    CGSize size = [model.contactTitle boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:0 attributes:@{ NSFontAttributeName: font } context:nil].size;
//    return ceilf(size.width) + 20;
//}
//
//-(void)setPickerFocused:(BOOL)pickerFocused
//{
//    _pickerFocused = pickerFocused;
//    
//    if (self.pickerFocused)
//    {
//        self.contactTitleLabel.textColor = [UIColor whiteColor];
//        self.contactTitleLabel.backgroundColor = self.tintColor;
//    }
//    else
//    {
//        self.contactTitleLabel.textColor = self.tintColor;
//        self.contactTitleLabel.backgroundColor = [UIColor colorWithRed: 0.9214 green: 0.9215 blue: 0.9214 alpha: 1.0];
//    }
//}
//
//@end
