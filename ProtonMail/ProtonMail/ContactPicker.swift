//
//  ContactPicker.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/26/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

//#defined DEBUG_BORDERS

@objc protocol ContactPickerDataSource : NSObjectProtocol {
    //optional
    @objc func contactModelsForContactPicker(contactPickerView: ContactPicker) -> [ContactPickerModelProtocol]
    @objc func selectedContactModelsForContactPicker(contactPickerView: ContactPicker) -> [ContactPickerModelProtocol]
}

@objc protocol ContactPickerDelegate : ContactCollectionViewDelegate {
    @objc optional func contactPicker(contactPicker: ContactPicker, didUpdateContentHeightTo newHeight: CGFloat)
    @objc optional func didShowFilteredContactsForContactPicker(contactPicker: ContactPicker)
    @objc optional func didHideFilteredContactsForContactPicker(contactPicker: ContactPicker)
    @objc optional func contactPicker(contactPicker: ContactPicker, didEnterCustomText text: String, needFocus focus: Bool)
    @objc optional func contactPicker(picker: ContactPicker, pasted text: String, needFocus focus: Bool)
    @objc optional func customFilterPredicate(searchString: String) -> NSPredicate
}


class ContactPicker: UIView, UITableViewDataSource, UITableViewDelegate {

    var delegate : ContactPickerDelegate?
    var datasource : ContactPickerDataSource?
    
    var originalHeight : CGFloat = -1
    var originalYOffset : CGFloat = -1
    
    var _showPrompt : Bool = true
    var _prompt : String = ContactPickerDefined.kPrompt
    var _maxVisibleRows : CGFloat = ContactPickerDefined.kMaxVisibleRows
    
    var keyboardHeight : CGFloat = 0
    
    var animationSpeed : CGFloat = ContactPickerDefined.kAnimationSpeed
    
    var allowsCompletionOfSelectedContacts : Bool = true
    var _enabled : Bool = true
    var hideWhenNoResult : Bool = false
    
    
    var contacts: [ContactPickerModelProtocol] = [ContactPickerModelProtocol]()
    var filteredContacts: [ContactPickerModelProtocol] = [ContactPickerModelProtocol]()

    var contactCollectionView : ContactCollectionView!
    var searchTableView : UITableView!
    var contactCollectionViewContentSize: CGSize = CGSize.zero
    var hasLoadedData : Bool = false
    
    var cellHeight : Int {
        get {
            return self.contactCollectionView.cellHeight
        }
        set {
            self.contactCollectionView.cellHeight = newValue
            self.contactCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    var contactsSelected : [ContactPickerModelProtocol] {
        get {
            return self.contactCollectionView.selectedContacts
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    
    func setup() {
        
        self._prompt = ContactPickerDefined.kPrompt
        self._showPrompt = true
        self.originalHeight = -1
        self.originalYOffset = -1
        
        let contactCollectionView = ContactCollectionView.contactCollectionViewWithFrame(frame: self.bounds)
        contactCollectionView.contactDelegate = self
        contactCollectionView.clipsToBounds = true
        contactCollectionView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contactCollectionView)
        self.contactCollectionView = contactCollectionView
        
        self.maxVisibleRows = ContactPickerDefined.kMaxVisibleRows
        self.animationSpeed = ContactPickerDefined.kAnimationSpeed
        
        self.allowsCompletionOfSelectedContacts = true
        self.translatesAutoresizingMaskIntoConstraints = false
        self.clipsToBounds = true
        
        self.enabled = true
        self.hideWhenNoResult = true
        
        let searchTableView = UITableView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
        searchTableView.dataSource = self
        searchTableView.delegate = self
        searchTableView.rowHeight = CGFloat(ContactPickerDefined.ROW_HEIGHT)
        searchTableView.translatesAutoresizingMaskIntoConstraints = false
        searchTableView.isHidden = true
        searchTableView.register(UINib.init(nibName: ContactPickerDefined.ContactsTableViewCellName, bundle: nil),
                                 forCellReuseIdentifier: ContactPickerDefined.ContactsTableViewCellIdentifier)
        self.addSubview(searchTableView)
        self.searchTableView = searchTableView
        
        self.contactCollectionView.setContentCompressionResistancePriority(.required,
                                                                           for: .vertical)
        
        self.searchTableView.setContentCompressionResistancePriority(.defaultLow,
                                                                     for: .vertical)
        

        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format: "V:|[contactCollectionView(>=%ld,<=%ld)][searchTableView(>=0)]|",
                                                                                    self.cellHeight,
                                                                                    self.cellHeight),
                                                           options: NSLayoutFormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["contactCollectionView" : contactCollectionView, "searchTableView" : searchTableView]))

        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[contactCollectionView]-(0@500)-|",
                                                           options: NSLayoutFormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["contactCollectionView" : contactCollectionView]))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[contactCollectionView]|",
                                                           options: NSLayoutFormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["contactCollectionView" : contactCollectionView]))

        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[searchTableView]|",
                                                           options: NSLayoutFormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["searchTableView" : searchTableView]))
        
        #if DEBUG_BORDERS
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.borderWidth = 1.0
        contactCollectionView.layer.borderColor = UIColor.red.cgColor
        contactCollectionView.layer.borderWidth = 1.0
        searchTableView.layer.borderColor = UIColor.blue.cgColor
        searchTableView.layer.borderWidth = 1.0
        #endif

    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    override func didMoveToWindow() {
        if self.window != nil {
            let nc = NotificationCenter.default
            nc.addObserver(self,
                           selector: #selector(ContactPicker.keyboardChangedStatus(notification:)),
                           name: NSNotification.Name.UIKeyboardWillShow,
                           object: nil)
            
            nc.addObserver(self,
                           selector: #selector(ContactPicker.keyboardChangedStatus(notification:)),
                           name: NSNotification.Name.UIKeyboardWillHide,
                           object: nil)
            
            if !self.hasLoadedData {
                self.reloadData()
                self.hasLoadedData = true
            }
        }
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        if newWindow == nil {
            let nc = NotificationCenter.default
            nc.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            nc.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        }
    }

    //
    //#pragma mark - Keyboard Notification Handling
    //
    @objc func keyboardChangedStatus(notification: NSNotification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.keyboardHeight = keyboardSize.height
        }
    }

    func reloadData() {
        self.contactCollectionView.selectedContacts.removeAll()
        
        if let delegate = self.datasource, delegate.responds(to: #selector(ContactPickerDataSource.selectedContactModelsForContactPicker(contactPickerView:))) {
            self.contactCollectionView.selectedContacts.append(contentsOf:delegate.selectedContactModelsForContactPicker(contactPickerView: self))
        }
        self.contacts = self.datasource?.contactModelsForContactPicker(contactPickerView: self) ?? [ContactPickerModelProtocol]()
        self.contactCollectionView.reloadData()
        
        self.layoutIfNeeded()
        self.contactCollectionView.layoutIfNeeded()
        self.contactCollectionView.scrollToEntryAnimated(animated: false, onComplete: nil)
        self.hideSearchTableView()
    }
    
    //
    //#pragma mark - Properties
    //
    var prompt : String {
        get {
            return self._prompt
        }
        set {
            self._prompt = newValue
            self.contactCollectionView.prompt = self._prompt
        }
    }

    var maxVisibleRows: CGFloat {
        get {
            return self._maxVisibleRows
        }
        set {
            self._maxVisibleRows = newValue
            self.contactCollectionView.collectionViewLayout.invalidateLayout()
        }
    }


    var currentContentHeight : CGFloat {
        get {
            let minimumSizeWithContent = max(CGFloat(self.cellHeight), self.contactCollectionViewContentSize.height)
            let maximumSize = self.maxVisibleRows * CGFloat(self.cellHeight)
            return min(minimumSizeWithContent, maximumSize)
        }
    }

    var enabled: Bool {
        get {
            return self._enabled
        }
        set {
            self._enabled = newValue
            self.contactCollectionView.allowsSelection = newValue
            self.contactCollectionView.allowsTextInput = newValue
            
            if (!newValue) {
                let _ = self.resignFirstResponder()
            }
        }
    }
    
    var showPrompt: Bool {
        get {
            return self._showPrompt
        }
        set {
            self._showPrompt = newValue
            self.contactCollectionView.showPrompt = newValue
        }
    }

    
    func addToSelectedContacts(model: ContactPickerModelProtocol, needFocus focus: Bool) {
        self.contactCollectionView.addToSelectedContacts(model: model) {
            if focus {
                let _ = self.becomeFirstResponder()
            }
        }
    }

    
    func addToSelectedContacts(model: ContactPickerModelProtocol, withCompletion completion: ContactPickerComplete?) {
        self.contactCollectionView.addToSelectedContacts(model: model, withCompletion: completion)
    }
    
    //
    //#pragma mark - UITableViewDataSource
    //
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredContacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactPickerDefined.ContactsTableViewCellIdentifier, for: indexPath) as! ContactsTableViewCell
        
        if (self.filteredContacts.count > indexPath.row) {
            let model = self.filteredContacts[indexPath.row]
            cell.contactEmailLabel.text = model.contactSubtitle
            cell.contactNameLabel.text = model.contactTitle
        }
        return cell
    }
    
    
    //
    //#pragma mark - UITableViewDelegate
    //
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.filteredContacts[indexPath.row]
        self.hideSearchTableView()
        self.contactCollectionView.addToSelectedContacts(model: model, withCompletion: nil)
    }
    
    //
    //#pragma mark - UIResponder
    //
    override var canBecomeFirstResponder: Bool {
        return false
    }
    
    override func becomeFirstResponder() -> Bool {
        if !self.enabled {
            return false
        }
        
        if !self.isFirstResponder {
            if let index = self.contactCollectionView.indexPathOfSelectedCell {
                self.contactCollectionView.scrollToItem(at: index, at: UICollectionViewScrollPosition(rawValue: 0), animated: true)
            } else {
                self.contactCollectionView.setFocusOnEntry()
            }
        }
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        
        return self.contactCollectionView.resignFirstResponder()
    }
    
    //
    //#pragma mark Helper Methods
    //
    func showSearchTableView() {
        self.searchTableView.isHidden = false
        if let delegate = self.delegate, delegate.responds(to: #selector(ContactPickerDelegate.didShowFilteredContactsForContactPicker(contactPicker:))) {
            delegate.didShowFilteredContactsForContactPicker!(contactPicker: self)
        }
    }
    
    func hideSearchTableView() {
        self.searchTableView.isHidden = true

        if let delegate = self.delegate, delegate.responds(to: #selector(ContactPickerDelegate.didHideFilteredContactsForContactPicker(contactPicker:))) {
            delegate.didHideFilteredContactsForContactPicker!(contactPicker: self)
        }
    }
    
    func updateCollectionViewHeightConstraints() {
        for constraint in self.constraints {
            if let firstItem = constraint.firstItem as? ContactCollectionView, firstItem == self.contactCollectionView {
                if constraint.firstAttribute == .height {
                    if constraint.relation == .greaterThanOrEqual {
                        constraint.constant = CGFloat( self.cellHeight )
                    } else if constraint.relation == .lessThanOrEqual {
                        constraint.constant = self.currentContentHeight
                    }
                }
            }
        }
    }

}

//
//#pragma mark - ContactCollectionViewDelegate
//
extension ContactPicker : ContactCollectionViewDelegate {
    func contactCollectionView(contactCollectionView: UICollectionView?, willChangeContentSizeTo newSize: CGSize) {
        if !__CGSizeEqualToSize(self.contactCollectionViewContentSize, newSize) {
            self.contactCollectionViewContentSize = newSize
            self.updateCollectionViewHeightConstraints()
            
            if let delegate = self.delegate, delegate.responds(to: #selector(ContactPickerDelegate.contactPicker(contactPicker:didUpdateContentHeightTo:))) {
                delegate.contactPicker!(contactPicker: self, didUpdateContentHeightTo: self.currentContentHeight)
            }
        }
    }
    
    func contactCollectionView(contactCollectionView: ContactCollectionView, entryTextDidChange text: String) {
    
        if text == " " {
            self.hideSearchTableView()
        }
        else
        {
            self.contactCollectionView.collectionViewLayout.invalidateLayout()
            
            self.contactCollectionView.performBatchUpdates({
                self.layoutIfNeeded()
            }) { (finished) in
                self.contactCollectionView.setFocusOnEntry()
            }
            self.showSearchTableView()
            
            let searchString = text.trimmingCharacters(in: NSCharacterSet.whitespaces)
            

            let predicate : NSPredicate!
            
            if let delegate = self.delegate, delegate.responds(to: #selector(ContactPickerDelegate.customFilterPredicate(searchString:))) {
                predicate = delegate.customFilterPredicate!(searchString: searchString)
            } else if self.allowsCompletionOfSelectedContacts {
                predicate = NSPredicate(format: "contactTitle contains[cd] %@", searchString)
            } else {
                predicate = NSPredicate(format: "contactTitle contains[cd] %@ && !SELF IN %@",
                                        searchString,
                                        self.contactCollectionView.selectedContacts)
            }
            self.filteredContacts = self.contacts.filter{ predicate.evaluate(with: $0) }
            
            if self.hideWhenNoResult && self.filteredContacts.count <= 0 {
                if !self.searchTableView.isHidden {
                    self.hideSearchTableView()
                }
            } else {
                if self.searchTableView.isHidden {
                    self.showSearchTableView()
                }
                self.searchTableView.reloadData()
            }
        }
    
    }
    
    func contactCollectionView(contactCollectionView: ContactCollectionView, didEnterCustomContact text: String, needFocus focus: Bool) {
        if let delegate = self.delegate, delegate.responds(to: #selector(ContactPickerDelegate.contactPicker(contactPicker:didEnterCustomText:needFocus:))) {
            delegate.contactPicker!(contactPicker: self, didEnterCustomText: text, needFocus: focus)
        }
        self.hideSearchTableView()
    }
    
    func contactCollectionView(contactCollectionView: ContactCollectionView, didSelectContact model: ContactPickerModelProtocol) {
        if let delegate = self.delegate, delegate.responds(to: #selector(ContactCollectionViewDelegate.contactCollectionView(contactCollectionView:didSelectContact:))) {
            delegate.contactCollectionView!(contactCollectionView: contactCollectionView, didSelectContact: model)
        }
    }
    
    func contactCollectionView(contactCollectionView: ContactCollectionView, didAddContact model: ContactPickerModelProtocol) {
        if let delegate = self.delegate, delegate.responds(to: #selector(ContactCollectionViewDelegate.contactCollectionView(contactCollectionView:didAddContact:))) {
            delegate.contactCollectionView!(contactCollectionView: contactCollectionView, didAddContact: model)
        }
    }
    
    func contactCollectionView(contactCollectionView: ContactCollectionView, didRemoveContact model: ContactPickerModelProtocol) {
        if let delegate = self.delegate, delegate.responds(to: #selector(ContactCollectionViewDelegate.contactCollectionView(contactCollectionView:didRemoveContact:))) {
            delegate.contactCollectionView!(contactCollectionView: contactCollectionView, didRemoveContact: model)
        }
    }
    
    func collectionView(in: ContactCollectionView, pasted text: String, needFocus focus: Bool) {
        if let delegate = self.delegate, delegate.responds(to: #selector(ContactPickerDelegate.contactPicker(picker:pasted:needFocus:))) {
            delegate.contactPicker!(picker: self, pasted: text, needFocus: focus)
        }
    }
}

