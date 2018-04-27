//
//  ContactPicker.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/26/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit


class ContactPicker: UIView {
    
    var delegate : MBContactPickerDelegate?
    var datasource : MBContactPickerDataSource?
    
    let originalHeight : CGFloat = -1
    let originalYOffset : CGFloat = -1
    
    
    var cellHeight : CGFloat = ContactPickerDefined.ROW_HEIGHT
    var showPrompt : Bool = true
    var prompt : String = ContactPickerDefined.kPrompt
    var maxVisibleRows : CGFloat = ContactPickerDefined.kMaxVisibleRows
    
    var currentContentHeight : CGFloat = 0
    var keyboardHeight : CGFloat = 0
    
    var animationSpeed : CGFloat = ContactPickerDefined.kAnimationSpeed
    var allowsCompletionOfSelectedContacts : Bool = true
    let enabled : Bool = true
    let hideWhenNoResult : Bool = true
    
    //    @property (nonatomic) NSArray *filteredContacts;
    //    @property (nonatomic) NSArray *contacts;
    //    @property (nonatomic) CGSize contactCollectionViewContentSize;
    //    @property (nonatomic) BOOL hasLoadedData;
    //    @property (nonatomic, strong) UIFont *font UI_APPEARANCE_SELECTOR;

    var contactCollectionView : ContactCollectionView!
    var searchTableView : UITableView!
    
//    @interface MBContactPicker : UIView <UITableViewDataSource, UITableViewDelegate, MBContactCollectionViewDelegate>

//    - (void)reloadData;
//    - (void)addToSelectedContacts:(id<MBContactPickerModelProtocol>)model needFocus:(BOOL)focus;
//    - (void)addToSelectedContacts:(id<MBContactPickerModelProtocol>)model withCompletion:(CompletionBlock)completion;
//    @end
    //
    //- (NSArray*)contactsSelected
    //{
    //    return self.contactCollectionView.selectedContacts;
    //    }
    //
    var contactsSelected : String {
        get {
            return ""
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    
    func setup() {
        self.clipsToBounds = true
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let contactCollectionView = ContactCollectionView.contactCollectionViewWithFrame(frame: self.bounds)
//        contactCollectionView.contactDelegate = self;
//        contactCollectionView.clipsToBounds = YES;
//        contactCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
        self.addSubview(contactCollectionView)
        self.contactCollectionView = contactCollectionView

        let searchTableView = UITableView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
//        searchTableView.dataSource = self;
//        searchTableView.delegate = self;
//        searchTableView.rowHeight = ROW_HEIGHT;
//        searchTableView.translatesAutoresizingMaskIntoConstraints = NO;
//        searchTableView.hidden = YES;
//        [searchTableView registerNib:[UINib nibWithNibName:ContactsTableViewCellName bundle:nil] forCellReuseIdentifier:ContactsTableViewCellIdentifier];
        self.addSubview(searchTableView)
        self.searchTableView = searchTableView
//
//
//        [contactCollectionView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
//        [searchTableView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
//
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[contactCollectionView(>=%ld,<=%ld)][searchTableView(>=0)]|", (long)self.cellHeight, (long)self.cellHeight]
//            options:0
//            metrics:nil
//            views:NSDictionaryOfVariableBindings(contactCollectionView, searchTableView)]];
//
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contactCollectionView]-(0@500)-|"
//            options:0
//            metrics:nil
//            views:NSDictionaryOfVariableBindings(contactCollectionView)]];
//
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contactCollectionView]|"
//            options:0
//            metrics:nil
//            views:NSDictionaryOfVariableBindings(contactCollectionView)]];
//
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchTableView]|"
//            options:0
//            metrics:nil
//            views:NSDictionaryOfVariableBindings(searchTableView)]];
//
        
//        #ifdef DEBUG_BORDERS
//        self.layer.borderColor = [UIColor grayColor].CGColor;
//        self.layer.borderWidth = 1.0;
//        contactCollectionView.layer.borderColor = [UIColor redColor].CGColor;
//        contactCollectionView.layer.borderWidth = 1.0;
//        searchTableView.layer.borderColor = [UIColor blueColor].CGColor;
//        searchTableView.layer.borderWidth = 1.0;
//        #endif
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    override func didMoveToWindow() {
        if self.window != nil {
//            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//            [nc addObserver:self selector:@selector(keyboardChangedStatus:) name:UIKeyboardWillShowNotification object:nil];
//            [nc addObserver:self selector:@selector(keyboardChangedStatus:) name:UIKeyboardWillHideNotification object:nil];
//
//            if (!self.hasLoadedData)
//            {
//                [self reloadData];
//                self.hasLoadedData = YES;
//            }
        }
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        if (newWindow == nil)
        {
//            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//            [nc removeObserver:self name:UIKeyboardWillShowNotification object:nil];
//            [nc removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        }
    }

//#pragma mark - Keyboard Notification Handling
//- (void)keyboardChangedStatus:(NSNotification*)notification
//{
//    CGRect keyboardRect;
//    [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];
//    self.keyboardHeight = keyboardRect.size.height;
//    }
//
//    - (void)reloadData
//        {
//            self.contactCollectionView.selectedContacts = [[NSMutableArray alloc] init];
//
//            if ([self.datasource respondsToSelector:@selector(selectedContactModelsForContactPicker:)])
//            {
//                [self.contactCollectionView.selectedContacts addObjectsFromArray:[self.datasource selectedContactModelsForContactPicker:self]];
//            }
//
//            self.contacts = [self.datasource contactModelsForContactPicker:self];
//
//            [self.contactCollectionView reloadData];
//            //[self layoutIfNeeded];
//            //[self.contactCollectionView layoutIfNeeded];
//            [self.contactCollectionView scrollToEntryAnimated:NO onComplete:nil];
//            //[self hideSearchTableView];
//}
//
//#pragma mark - Properties

//    - (void)setCellHeight:(NSInteger)cellHeight
//{
//    self.contactCollectionView.cellHeight = cellHeight;
//    [self.contactCollectionView.collectionViewLayout invalidateLayout];
//    }
//
//    - (NSInteger)cellHeight
//        {
//            return self.contactCollectionView.cellHeight;
//        }
//
//        - (void)setPrompt:(NSString *)prompt
//{
//    _prompt = [prompt copy];
//    self.contactCollectionView.prompt = _prompt;
//    }
//
//    - (void)setMaxVisibleRows:(CGFloat)maxVisibleRows
//{
//    _maxVisibleRows = maxVisibleRows;
//    [self.contactCollectionView.collectionViewLayout invalidateLayout];
//    }
//
//    - (CGFloat)currentContentHeight
//        {
//            CGFloat minimumSizeWithContent = MAX(self.cellHeight, self.contactCollectionViewContentSize.height);
//            CGFloat maximumSize = self.maxVisibleRows * self.cellHeight;
//            return MIN(minimumSizeWithContent, maximumSize);
//        }
//
//        - (void)setEnabled:(BOOL)enabled
//{
//    _enabled = enabled;
//
//    self.contactCollectionView.allowsSelection = enabled;
//    self.contactCollectionView.allowsTextInput = enabled;
//
//    if (!enabled)
//    {
//        [self resignFirstResponder];
//    }
//    }
//
//    - (void)setShowPrompt:(BOOL)showPrompt
//{
//    _showPrompt = showPrompt;
//    self.contactCollectionView.showPrompt = showPrompt;
//    }
//
//    - (void)addToSelectedContacts:(id<MBContactPickerModelProtocol>)model withCompletion:(CompletionBlock)completion
//{
//    [self.contactCollectionView addToSelectedContacts:model withCompletion:completion];
//}
//
//#pragma mark - UITableViewDataSource
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    return self.filteredContacts.count;
//    }
//
//    - (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    ContactsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ContactsTableViewCellIdentifier forIndexPath:indexPath];
//
//    if (self.filteredContacts.count > indexPath.row) {
//        ContactVO<MBContactPickerModelProtocol> *model = self.filteredContacts[indexPath.row];
//
//        cell.contactEmailLabel.text = model.contactSubtitle;
//        cell.contactNameLabel.text = model.contactTitle;
//    }
//    return cell;
//}
//
//#pragma mark - UITableViewDelegate
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    id<MBContactPickerModelProtocol> model = self.filteredContacts[indexPath.row];
//
//    [self hideSearchTableView];
//    [self.contactCollectionView addToSelectedContacts:model withCompletion:nil];
//}
//
//#pragma mark - ContactCollectionViewDelegate
//
//- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView willChangeContentSizeTo:(CGSize)newSize
//{
//    if (!CGSizeEqualToSize(self.contactCollectionViewContentSize, newSize))
//    {
//        self.contactCollectionViewContentSize = newSize;
//        [self updateCollectionViewHeightConstraints];
//
//        if ([self.delegate respondsToSelector:@selector(contactPicker:didUpdateContentHeightTo:)])
//        {
//            [self.delegate contactPicker:self didUpdateContentHeightTo:self.currentContentHeight];
//        }
//    }
//    }
//
//    - (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView entryTextDidChange:(NSString*)text
//{
//    if ([text isEqualToString:@" "])
//    {
//        [self hideSearchTableView];
//    }
//    else
//    {
//        [self.contactCollectionView.collectionViewLayout invalidateLayout];
//
//        [self.contactCollectionView performBatchUpdates:^{
//            [self layoutIfNeeded];
//            } completion:^(BOOL finished) {
//            [self.contactCollectionView setFocusOnEntry];
//            }];
//
//        [self showSearchTableView];
//        NSString *searchString = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//        NSPredicate *predicate;
//
//        if ([self.delegate respondsToSelector:@selector(customFilterPredicate:)])
//        {
//            predicate = [self.delegate customFilterPredicate:searchString];
//        } else if (self.allowsCompletionOfSelectedContacts) {
//            predicate = [NSPredicate predicateWithFormat:@"contactTitle contains[cd] %@", searchString];
//        } else {
//            predicate = [NSPredicate predicateWithFormat:@"contactTitle contains[cd] %@ && !SELF IN %@", searchString, self.contactCollectionView.selectedContacts];
//        }
//        self.filteredContacts = [self.contacts filteredArrayUsingPredicate:predicate];
//
//        if(self.hideWhenNoResult && self.filteredContacts.count <= 0)
//        {
//            if (!self.searchTableView.hidden) {
//                [self hideSearchTableView];
//            }
//        }
//        else
//        {
//            if (self.searchTableView.hidden) {
//                [self showSearchTableView];
//            }
//            [self.searchTableView reloadData];
//        }
//    }
//    }
//
//    - (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didRemoveContact:(id<MBContactPickerModelProtocol>)model
//{
//    if ([self.delegate respondsToSelector:@selector(contactCollectionView:didRemoveContact:)])
//    {
//        [self.delegate contactCollectionView:contactCollectionView didRemoveContact:model];
//    }
//    }
//
//    - (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didAddContact:(id<MBContactPickerModelProtocol>)model
//{
//    if ([self.delegate respondsToSelector:@selector(contactCollectionView:didAddContact:)])
//    {
//        [self.delegate contactCollectionView:contactCollectionView didAddContact:model];
//    }
//    }
//
//    - (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didSelectContact:(id<MBContactPickerModelProtocol>)model
//{
//    if ([self.delegate respondsToSelector:@selector(contactCollectionView:didSelectContact:)])
//    {
//        [self.delegate contactCollectionView:contactCollectionView didSelectContact:model];
//    }
//    }
//
//
//    - (void) contactCollectionView:(MBContactCollectionView*)contactCollectionView didEnterCustomContact:(NSString*)text needFocus:(BOOL)focus
//{
//    if ([self.delegate respondsToSelector:@selector(contactPicker:didEnterCustomText:needFocus:)])
//    {
//        [self.delegate contactPicker:self didEnterCustomText:text needFocus:focus];
//        [self hideSearchTableView];
//    }
//    }
//
//    - (void)addToSelectedContacts:(id<MBContactPickerModelProtocol>)model needFocus:(BOOL)focus
//{
//    [self.contactCollectionView addToSelectedContacts:model withCompletion:^{
//        if (focus) {
//        [self becomeFirstResponder];
//        }
//        }];
//}
//
//#pragma mark - UIResponder
//
//- (BOOL)canBecomeFirstResponder
//{
//    return NO;
//    }
//
//    - (BOOL)becomeFirstResponder
//        {
//            if (!self.enabled)
//            {
//                return NO;
//            }
//
//            if (![self isFirstResponder])
//            {
//                if (self.contactCollectionView.indexPathOfSelectedCell)
//                {
//                    [self.contactCollectionView scrollToItemAtIndexPath:self.contactCollectionView.indexPathOfSelectedCell atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
//                }
//                else
//                {
//                    [self.contactCollectionView setFocusOnEntry];
//                }
//            }
//
//            return YES;
//        }
//
//        - (BOOL)resignFirstResponder
//            {
//                [super resignFirstResponder];
//                return [self.contactCollectionView resignFirstResponder];
//}
//
//#pragma mark Helper Methods
//
//- (void)showSearchTableView
//{
//    self.searchTableView.hidden = NO;
//    if ([self.delegate respondsToSelector:@selector(didShowFilteredContactsForContactPicker:)])
//    {
//        [self.delegate didShowFilteredContactsForContactPicker:self];
//    }
//    }
//
//    - (void)hideSearchTableView
//        {
//            self.searchTableView.hidden = YES;
//            if ([self.delegate respondsToSelector:@selector(didHideFilteredContactsForContactPicker:)])
//            {
//                [self.delegate didHideFilteredContactsForContactPicker:self];
//            }
//        }
//
//        - (void)updateCollectionViewHeightConstraints
//            {
//                for (NSLayoutConstraint *constraint in self.constraints)
//                {
//                    if (constraint.firstItem == self.contactCollectionView)
//                    {
//                        if (constraint.firstAttribute == NSLayoutAttributeHeight)
//                        {
//                            if (constraint.relation == NSLayoutRelationGreaterThanOrEqual)
//                            {
//                                constraint.constant = self.cellHeight;
//                            }
//                            else if (constraint.relation == NSLayoutRelationLessThanOrEqual)
//                            {
//                                constraint.constant = self.currentContentHeight;
//                            }
//                        }
//                    }
//                }
//}
//
//@end

}

//extension ContactPicker : UITableViewDataSource, UITableViewDelegate, MBContactCollectionViewDelegate {
//
//}
//

