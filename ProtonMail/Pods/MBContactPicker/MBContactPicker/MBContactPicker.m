//
//  MBContactPicker.m
//  MBContactPicker
//
//  Created by Matt Bowman on 12/2/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import "MBContactPicker.h"

CGFloat const kMaxVisibleRows = 2;
NSString * const kMBPrompt = @"To:";
CGFloat const kAnimationSpeed = .25;

@interface MBContactPicker()

@property (nonatomic, weak) MBContactCollectionView *contactCollectionView;
@property (nonatomic, weak) UITableView *searchTableView;
@property (nonatomic) NSArray *filteredContacts;
@property (nonatomic) NSArray *contacts;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) CGSize contactCollectionViewContentSize;

@property CGFloat originalHeight;
@property CGFloat originalYOffset;

@property (nonatomic) BOOL hasLoadedData;

@end

@implementation MBContactPicker

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)didMoveToWindow
{
    if (self.window)
    {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(keyboardChangedStatus:) name:UIKeyboardWillShowNotification object:nil];
        [nc addObserver:self selector:@selector(keyboardChangedStatus:) name:UIKeyboardWillHideNotification object:nil];
        
        if (!self.hasLoadedData)
        {
            [self reloadData];
            self.hasLoadedData = YES;
        }
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (newWindow == nil)
    {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [nc removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)setup
{
    _prompt = kMBPrompt;
    _showPrompt = YES;
    
    self.originalHeight = -1;
    self.originalYOffset = -1;
    self.maxVisibleRows = kMaxVisibleRows;
    self.animationSpeed = kAnimationSpeed;
    self.allowsCompletionOfSelectedContacts = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.clipsToBounds = YES;
    self.enabled = YES;
    
    MBContactCollectionView *contactCollectionView = [MBContactCollectionView contactCollectionViewWithFrame:self.bounds];
    contactCollectionView.contactDelegate = self;
    contactCollectionView.clipsToBounds = YES;
    contactCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:contactCollectionView];
    self.contactCollectionView = contactCollectionView;

    UITableView *searchTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height, self.bounds.size.width, 0)];
    searchTableView.dataSource = self;
    searchTableView.delegate = self;
    searchTableView.translatesAutoresizingMaskIntoConstraints = NO;
    searchTableView.hidden = YES;
    [self addSubview:searchTableView];
    self.searchTableView = searchTableView;
    
    
    [contactCollectionView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [searchTableView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[contactCollectionView(>=%ld,<=%ld)][searchTableView(>=0)]|", (long)self.cellHeight, (long)self.cellHeight]
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(contactCollectionView, searchTableView)]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contactCollectionView]-(0@500)-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(contactCollectionView)]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contactCollectionView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(contactCollectionView)]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchTableView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(searchTableView)]];
    
    
#ifdef DEBUG_BORDERS
    self.layer.borderColor = [UIColor grayColor].CGColor;
    self.layer.borderWidth = 1.0;
    contactCollectionView.layer.borderColor = [UIColor redColor].CGColor;
    contactCollectionView.layer.borderWidth = 1.0;
    searchTableView.layer.borderColor = [UIColor blueColor].CGColor;
    searchTableView.layer.borderWidth = 1.0;
#endif
}

#pragma mark - Keyboard Notification Handling
- (void)keyboardChangedStatus:(NSNotification*)notification
{
    CGRect keyboardRect;
    [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];
    self.keyboardHeight = keyboardRect.size.height;
}

- (void)reloadData
{
    self.contactCollectionView.selectedContacts = [[NSMutableArray alloc] init];
    
    if ([self.datasource respondsToSelector:@selector(selectedContactModelsForContactPicker:)])
    {
        [self.contactCollectionView.selectedContacts addObjectsFromArray:[self.datasource selectedContactModelsForContactPicker:self]];
    }
    
    self.contacts = [self.datasource contactModelsForContactPicker:self];
    
    [self.contactCollectionView reloadData];
    [self.contactCollectionView scrollToEntryAnimated:NO onComplete:nil];
}

#pragma mark - Properties

- (NSArray*)contactsSelected
{
    return self.contactCollectionView.selectedContacts;
}

- (void)setCellHeight:(NSInteger)cellHeight
{
    self.contactCollectionView.cellHeight = cellHeight;
    [self.contactCollectionView.collectionViewLayout invalidateLayout];
}

- (NSInteger)cellHeight
{
    return self.contactCollectionView.cellHeight;
}

- (void)setPrompt:(NSString *)prompt
{
    _prompt = [prompt copy];
    self.contactCollectionView.prompt = _prompt;
}

- (void)setMaxVisibleRows:(CGFloat)maxVisibleRows
{
    _maxVisibleRows = maxVisibleRows;
    [self.contactCollectionView.collectionViewLayout invalidateLayout];
}

- (CGFloat)currentContentHeight
{
    CGFloat minimumSizeWithContent = MAX(self.cellHeight, self.contactCollectionViewContentSize.height);
    CGFloat maximumSize = self.maxVisibleRows * self.cellHeight;
    return MIN(minimumSizeWithContent, maximumSize);
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    
    self.contactCollectionView.allowsSelection = enabled;
    self.contactCollectionView.allowsTextInput = enabled;
    
    if (!enabled)
    {
        [self resignFirstResponder];
    }
}

- (void)setShowPrompt:(BOOL)showPrompt
{
    _showPrompt = showPrompt;
    self.contactCollectionView.showPrompt = showPrompt;
}

- (void)addToSelectedContacts:(id<MBContactPickerModelProtocol>)model withCompletion:(CompletionBlock)completion
{
    [self.contactCollectionView addToSelectedContacts:model withCompletion:completion];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredContacts.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"Cell"];
    }

    id<MBContactPickerModelProtocol> model = (id<MBContactPickerModelProtocol>)self.filteredContacts[indexPath.row];

    cell.textLabel.text = model.contactTitle;
    UIFont *font = [[self.class appearance] font];
    if (font)
    {
        cell.textLabel.font = font;
    }

    cell.detailTextLabel.text = nil;
    cell.imageView.image = nil;
    
    if ([model respondsToSelector:@selector(contactSubtitle)])
    {
        cell.detailTextLabel.text = model.contactSubtitle;
    }
    
    if ([model respondsToSelector:@selector(contactImage)])
    {
        cell.imageView.image = model.contactImage;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<MBContactPickerModelProtocol> model = self.filteredContacts[indexPath.row];
    
    [self hideSearchTableView];
    [self.contactCollectionView addToSelectedContacts:model withCompletion:nil];
}

#pragma mark - ContactCollectionViewDelegate

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView willChangeContentSizeTo:(CGSize)newSize
{
    if (!CGSizeEqualToSize(self.contactCollectionViewContentSize, newSize))
    {
        self.contactCollectionViewContentSize = newSize;
        [self updateCollectionViewHeightConstraints];
        
        if ([self.delegate respondsToSelector:@selector(contactPicker:didUpdateContentHeightTo:)])
        {
            [self.delegate contactPicker:self didUpdateContentHeightTo:self.currentContentHeight];
        }
    }
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView entryTextDidChange:(NSString*)text
{
    if ([text isEqualToString:@" "])
    {
        [self hideSearchTableView];
    }
    else
    {
        [self.contactCollectionView.collectionViewLayout invalidateLayout];
        
        [self.contactCollectionView performBatchUpdates:^{
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
             [self.contactCollectionView setFocusOnEntry];
        }];
        
        [self showSearchTableView];
        NSString *searchString = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSPredicate *predicate;
        
        if ([self.delegate respondsToSelector:@selector(customFilterPredicate:)])
        {
            predicate = [self.delegate customFilterPredicate:searchString];
        } else if (self.allowsCompletionOfSelectedContacts) {
            predicate = [NSPredicate predicateWithFormat:@"contactTitle contains[cd] %@", searchString];
        } else {
            predicate = [NSPredicate predicateWithFormat:@"contactTitle contains[cd] %@ && !SELF IN %@", searchString, self.contactCollectionView.selectedContacts];
        }
        self.filteredContacts = [self.contacts filteredArrayUsingPredicate:predicate];
        [self.searchTableView reloadData];
    }
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didRemoveContact:(id<MBContactPickerModelProtocol>)model
{
    if ([self.delegate respondsToSelector:@selector(contactCollectionView:didRemoveContact:)])
    {
        [self.delegate contactCollectionView:contactCollectionView didRemoveContact:model];
    }
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didAddContact:(id<MBContactPickerModelProtocol>)model
{
    if ([self.delegate respondsToSelector:@selector(contactCollectionView:didAddContact:)])
    {
        [self.delegate contactCollectionView:contactCollectionView didAddContact:model];
    }
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didSelectContact:(id<MBContactPickerModelProtocol>)model
{
    if ([self.delegate respondsToSelector:@selector(contactCollectionView:didSelectContact:)])
    {
        [self.delegate contactCollectionView:contactCollectionView didSelectContact:model];
    }
}

- (void) contactCollectionView:(MBContactCollectionView *)contactCollectionView didEnterCustomContact:(NSString *)text
{
    if ([self.delegate respondsToSelector:@selector(contactPicker:didEnterCustomText:)])
    {
        [self.delegate contactPicker:self didEnterCustomText:text];
        [self hideSearchTableView];
    }
}

- (void)addToSelectedContacts:(id<MBContactPickerModelProtocol>)model
{
    [self.contactCollectionView addToSelectedContacts:model withCompletion:^{
        [self becomeFirstResponder];
    }];
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder
{
    return NO;
}

- (BOOL)becomeFirstResponder
{
    if (!self.enabled)
    {
        return NO;
    }
    
    if (![self isFirstResponder])
    {
        if (self.contactCollectionView.indexPathOfSelectedCell)
        {
            [self.contactCollectionView scrollToItemAtIndexPath:self.contactCollectionView.indexPathOfSelectedCell atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
        }
        else
        {
            [self.contactCollectionView setFocusOnEntry];
        }
    }
    
    return YES;
}

- (BOOL)resignFirstResponder
{
    return [self.contactCollectionView resignFirstResponder];
}

#pragma mark Helper Methods

- (void)showSearchTableView
{
    self.searchTableView.hidden = NO;
    if ([self.delegate respondsToSelector:@selector(didShowFilteredContactsForContactPicker:)])
    {
        [self.delegate didShowFilteredContactsForContactPicker:self];
    }
}

- (void)hideSearchTableView
{
    self.searchTableView.hidden = YES;
    if ([self.delegate respondsToSelector:@selector(didHideFilteredContactsForContactPicker:)])
    {
        [self.delegate didHideFilteredContactsForContactPicker:self];
    }
}

- (void)updateCollectionViewHeightConstraints
{
    for (NSLayoutConstraint *constraint in self.constraints)
    {
        if (constraint.firstItem == self.contactCollectionView)
        {
            if (constraint.firstAttribute == NSLayoutAttributeHeight)
            {
                if (constraint.relation == NSLayoutRelationGreaterThanOrEqual)
                {
                    constraint.constant = self.cellHeight;
                }
                else if (constraint.relation == NSLayoutRelationLessThanOrEqual)
                {
                    constraint.constant = self.currentContentHeight;
                }
            }
        }
    }
}

@end
