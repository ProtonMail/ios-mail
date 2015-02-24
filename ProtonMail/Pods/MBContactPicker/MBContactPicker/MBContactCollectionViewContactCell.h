//
//  ContactCollectionViewCell.h
//  MBContactPicker
//
//  Created by Matt Bowman on 11/20/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBContactModel.h"

@interface MBContactCollectionViewContactCell : UICollectionViewCell

@property (nonatomic, strong) id<MBContactPickerModelProtocol> model;
@property (nonatomic) BOOL focused;
@property (nonatomic, strong) UIFont *font UI_APPEARANCE_SELECTOR;

- (CGFloat)widthForCellWithContact:(id<MBContactPickerModelProtocol>)model;

@end
