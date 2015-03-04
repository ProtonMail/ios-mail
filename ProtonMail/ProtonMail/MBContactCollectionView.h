//
//  ContactCollectionView.h
//  MBContactPicker
//
//  Created by Matt Bowman on 11/20/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBContactCollectionViewContactCell.h"
#import "MBContactCollectionViewEntryCell.h"
#import "MBContactCollectionViewPromptCell.h"
#import "MBContactCollectionViewFlowLayout.h"

@class MBContactCollectionView;

@protocol MBContactCollectionViewDelegate <NSObject>

@optional

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView willChangeContentSizeTo:(CGSize)newSize;
- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView entryTextDidChange:(NSString*)text;
- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didEnterCustomContact:(NSString*)text;
- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didSelectContact:(id<MBContactPickerModelProtocol>)model;
- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didAddContact:(id<MBContactPickerModelProtocol>)model;
- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didRemoveContact:(id<MBContactPickerModelProtocol>)model;
- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didEnterCustomText:(NSString*)text;

@end

@interface MBContactCollectionView : UICollectionView

@property (nonatomic) NSMutableArray *selectedContacts;
@property (nonatomic, weak) IBOutlet id<MBContactCollectionViewDelegate> contactDelegate;

- (void)addToSelectedContacts:(id<MBContactPickerModelProtocol>)model withCompletion:(void(^)())completion;
- (void)removeFromSelectedContacts:(NSInteger)index withCompletion:(void(^)())completion;
- (void)setFocusOnEntry;
- (void)scrollToEntryAnimated:(BOOL)animated onComplete:(void(^)())complete;
- (BOOL)isEntryCell:(NSIndexPath*)indexPath;
- (BOOL)isPromptCell:(NSIndexPath*)indexPath;
- (BOOL)isContactCell:(NSIndexPath*)indexPath;
- (NSInteger)entryCellIndex;
- (NSInteger)selectedContactIndexFromIndexPath:(NSIndexPath*)indexPath;
- (NSInteger)selectedContactIndexFromRow:(NSInteger)row;
- (NSIndexPath*)indexPathOfSelectedCell;

+ (MBContactCollectionView*)contactCollectionViewWithFrame:(CGRect)frame;

@property (nonatomic) NSInteger cellHeight;
@property (nonatomic, copy) NSString *prompt;
@property (nonatomic) BOOL allowsTextInput;
@property (nonatomic) BOOL showPrompt;

@end
