//
//  ContactCollectionViewEntryCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/27/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

//
//@protocol UITextFieldDelegateImproved <UITextFieldDelegate>
//
//- (void)textFieldDidChange:(UITextField*)textField;
//
//@end
//
//@interface MBContactCollectionViewEntryCell : UICollectionViewCell
//
//@property (nonatomic, weak) id<UITextFieldDelegateImproved> delegate;
//@property (nonatomic, copy) NSString *text;
//@property (nonatomic) BOOL enabled;
//@property (nonatomic, strong) UIFont *font UI_APPEARANCE_SELECTOR;
//
//- (void)setFocus;
//- (void)removeFocus;
//- (void)reset;
//- (CGFloat)widthForText:(NSString*)text;
//
//@end

class ContactCollectionViewEntryCell: UICollectionViewCell {
    
}





//
//@interface MBContactCollectionViewEntryCell()
//
//@property (nonatomic, weak) UITextField *contactEntryTextField;
//
//@end
//
//@implementation MBContactCollectionViewEntryCell
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
//        - (void)layoutSubviews
//            {
//                [super layoutSubviews];
//            }
//
//            - (void)setup
//                {
//                    UITextField *textField = [[UITextField alloc] initWithFrame:self.bounds];
//                    textField.delegate = self.delegate;
//                    textField.text = @" ";
//                    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
//                    textField.autocorrectionType = UITextAutocorrectionTypeNo;
//                    textField.spellCheckingType = UITextSpellCheckingTypeNo;
//                    textField.keyboardType =UIKeyboardTypeEmailAddress;
//
//                    UIFont *font = [[self.class appearance] font];
//                    if (font)
//                    {
//                        textField.font = font;
//                    }
//                    #ifdef DEBUG_BORDERS
//                    self.layer.borderColor = [UIColor orangeColor].CGColor;
//                    self.layer.borderWidth = 1.0;
//                    textField.layer.borderColor = [UIColor greenColor].CGColor;
//                    textField.layer.borderWidth = 2.0;
//#endif
//[self addSubview:textField];
//self.contactEntryTextField = textField;
//[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textField]|"
//    options:0
//    metrics:nil
//    views:NSDictionaryOfVariableBindings(textField)]];
//[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textField]|"
//    options:0
//    metrics:nil
//    views:NSDictionaryOfVariableBindings(textField)]];
//self.contactEntryTextField.translatesAutoresizingMaskIntoConstraints = NO;
//}
//
//- (void)setDelegate:(id<UITextFieldDelegateImproved>)delegate
//{
//    if (_delegate)
//    {
//        [self.contactEntryTextField removeTarget:_delegate action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
//    }
//
//    _delegate = delegate;
//    [self.contactEntryTextField addTarget:delegate action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
//    self.contactEntryTextField.delegate = delegate;
//    }
//
//    - (NSString*)text
//        {
//            return self.contactEntryTextField.text;
//        }
//
//        - (void)setText:(NSString *)text
//{
//    self.contactEntryTextField.text = text;
//    }
//
//    - (void)setEnabled:(BOOL)enabled
//{
//    _enabled = enabled;
//
//    self.contactEntryTextField.enabled = enabled;
//    }
//
//    - (void)reset
//        {
//            self.contactEntryTextField.text = @" ";
//            [self.delegate textFieldDidChange:self.contactEntryTextField];
//        }
//
//        - (void)setFocus
//            {
//                if (self.contactEntryTextField != nil ) {
//                    [self.contactEntryTextField becomeFirstResponder];
//                }
//            }
//
//            - (void)removeFocus
//                {
//                    [self.contactEntryTextField resignFirstResponder];
//                }
//
//                - (CGFloat)widthForText:(NSString *)text
//{
//    CGFloat width = [text boundingRectWithSize:(CGSize){ .width = CGFLOAT_MAX, .height = CGFLOAT_MAX }
//        options:NSStringDrawingUsesLineFragmentOrigin
//        attributes:@{ NSFontAttributeName: self.contactEntryTextField.font }
//        context:nil].size.width;
//    return ceilf(width);
//}
//
//@end
