//
//  ContactCollectionViewPromptCell.h
//  MBContactPicker
//
//  Created by Matt Bowman on 12/1/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MBContactCollectionViewPromptCell : UICollectionViewCell

@property (nonatomic, copy) NSString *prompt;
@property (nonatomic) UIEdgeInsets insets;
@property (nonatomic, strong) UIFont *font UI_APPEARANCE_SELECTOR;

+ (CGFloat)widthWithPrompt:(NSString *)prompt;

@end
