//
//  ContactPicker.swift
//  ProtonMail - Created on 4/26/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit

protocol ContactPickerDataSource: NSObjectProtocol {
    //optional
    func contactModelsForContactPicker(contactPickerView: ContactPicker) -> [ContactPickerModelProtocol]
    func selectedContactModelsForContactPicker(contactPickerView: ContactPicker) -> [ContactPickerModelProtocol]
    //
    func picker(contactPicker :ContactPicker, model: ContactPickerModelProtocol, progress: () -> Void, complete: ((UIImage?, Int) -> Void)?)
}

protocol ContactPickerDelegate: ContactCollectionViewDelegate {
    func contactPicker(contactPicker: ContactPicker, didUpdateContentHeightTo newHeight: CGFloat)
    func didShowFilteredContactsForContactPicker(contactPicker: ContactPicker)
    func didHideFilteredContactsForContactPicker(contactPicker: ContactPicker)
    func contactPicker(contactPicker: ContactPicker, didEnterCustomText text: String, needFocus focus: Bool)
    func contactPicker(picker: ContactPicker, pasted text: String, needFocus focus: Bool)
    
    func useCustomFilter() -> Bool
    func customFilterPredicate(searchString: String) -> NSPredicate
    
    func finishLockCheck()
}

class ContactPicker: UIView, AccessibleView {
    private var keyboardFrame: CGRect = .zero
    private var searchTableViewController: ContactSearchTableViewController?
    
    private func createSearchTableViewController() -> ContactSearchTableViewController {
        let controller = ContactSearchTableViewController()
        controller.tableView.register(UINib.init(nibName: ContactPickerDefined.ContactsTableViewCellName,
                                                 bundle: nil),
                                 forCellReuseIdentifier: ContactPickerDefined.ContactsTableViewCellIdentifier)
        controller.tableView.translatesAutoresizingMaskIntoConstraints = false
        controller.tableView.estimatedRowHeight = 60.0
        controller.tableView.sectionHeaderHeight = 0
        controller.tableView.sectionFooterHeight = 0
        controller.tableView.reloadData()
        controller.tableView.contentInsetAdjustmentBehavior = .never
        controller.onSelection = { [unowned self] model in
            self.hideSearchTableView()
            // if contact group is selected, we add all emails in it as selected, initially
            if let contactGroup = model as? ContactGroupVO {
                contactGroup.selectAllEmailFromGroup()
            }
            self.contactCollectionView.addToSelectedContacts(model: model, withCompletion: nil)
        }
        return controller
    }
    
    @objc private func keyboardShown(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        self.keyboardFrame = keyboardFrame
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            self.keyboardFrame = .zero
        }
    }
    
    internal weak var delegate : (ContactPickerDelegate&UIViewController)?
    internal weak var datasource : ContactPickerDataSource?
    
    private var _showPrompt : Bool = true
    private var _prompt : String = ContactPickerDefined.kPrompt
    private var _maxVisibleRows : CGFloat = ContactPickerDefined.kMaxVisibleRows
    private var animationSpeed : CGFloat = ContactPickerDefined.kAnimationSpeed
    private var allowsCompletionOfSelectedContacts : Bool = true
    private var _enabled : Bool = true
    private var hideWhenNoResult : Bool = false
    
    private var contacts: [ContactPickerModelProtocol] = [ContactPickerModelProtocol]()

    internal var contactCollectionView : ContactCollectionView!
    
    private var contactCollectionViewContentSize: CGSize = CGSize.zero
    private var hasLoadedData : Bool = false
    
    internal var cellHeight : Int {
        get {
            return self.contactCollectionView.cellHeight
        }
        set {
            self.contactCollectionView.cellHeight = newValue
            self.contactCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    internal var contactsSelected : [ContactPickerModelProtocol] {
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // this can not be done in deinit cuz Share Extension freaks out when subwindow is deinitialized after host window
    func prepareForDesctruction() {
        // nothing
    }
    
    private func setup() {
        self._prompt = ContactPickerDefined.kPrompt
        self._showPrompt = true
        
        let contactCollectionView = ContactCollectionView.contactCollectionViewWithFrame(frame: self.bounds)
        contactCollectionView.contactDelegate = self
        contactCollectionView.clipsToBounds = true
        contactCollectionView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contactCollectionView)
        
        self.contactCollectionView = contactCollectionView
        
        self.contactCollectionView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.contactCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.contactCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4).isActive = true
        self.contactCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        
        self.maxVisibleRows = ContactPickerDefined.kMaxVisibleRows
        self.animationSpeed = ContactPickerDefined.kAnimationSpeed
        
        self.allowsCompletionOfSelectedContacts = true
        self.translatesAutoresizingMaskIntoConstraints = false
        self.clipsToBounds = true
        
        self.enabled = true
        self.hideWhenNoResult = true

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardShown(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardShown(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        generateAccessibilityIdentifiers()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    //
    //#pragma mark - Keyboard Notification Handling
    //

    internal func reloadData() {
        self.contactCollectionView.selectedContacts.removeAll()
        
        if let selected = self.datasource?.selectedContactModelsForContactPicker(contactPickerView: self) {
             self.contactCollectionView.selectedContacts.append(contentsOf:selected)
        }
        
        self.contacts = self.datasource?.contactModelsForContactPicker(contactPickerView: self) ?? [ContactPickerModelProtocol]()
//        self.contactCollectionView.reloadData()
        
        self.layoutIfNeeded()
        self.contactCollectionView.layoutIfNeeded()
        self.contactCollectionView.scrollToEntryAnimated(animated: false, onComplete: nil)
        self.hideSearchTableView()
        
        //Show search result
        collectionView(at: self.contactCollectionView, entryTextDidChange: self.contactCollectionView.searchText)
    }
    
    
    func reload() {
        self.contactCollectionView.reloadData()
    }
    
    //
    //#pragma mark - Properties
    //
    internal var prompt : String {
        get {
            return self._prompt
        }
        set {
            self._prompt = newValue
            self.contactCollectionView.prompt = self._prompt
        }
    }

    private var maxVisibleRows: CGFloat {
        get {
            return self._maxVisibleRows
        }
        set {
            self._maxVisibleRows = newValue
            self.contactCollectionView.collectionViewLayout.invalidateLayout()
        }
    }


    internal var currentContentHeight : CGFloat {
        get {
            let minimumSizeWithContent = max(CGFloat(self.cellHeight), self.contactCollectionViewContentSize.height)
            let maximumSize = self.maxVisibleRows * CGFloat(self.cellHeight)
            return min(minimumSizeWithContent, maximumSize)
        }
    }

    private var enabled: Bool {
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
    
    private var showPrompt: Bool {
        get {
            return self._showPrompt
        }
        set {
            self._showPrompt = newValue
            self.contactCollectionView.showPrompt = newValue
        }
    }

    
    internal func addToSelectedContacts(model: ContactPickerModelProtocol, needFocus focus: Bool) {
        self.contactCollectionView.addToSelectedContacts(model: model) {
            if focus {
                let _ = self.becomeFirstResponder()
            }
        }
    }

    
    private func addToSelectedContacts(model: ContactPickerModelProtocol, withCompletion completion: ContactPickerComplete?) {
        self.contactCollectionView.addToSelectedContacts(model: model, withCompletion: completion)
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
                self.contactCollectionView.scrollToItem(at: index, at: UICollectionView.ScrollPosition(rawValue: 0), animated: true)
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
    
    override func didMoveToWindow() {
        if self.window != nil {
            if !self.hasLoadedData {
                self.reloadData()
                self.hasLoadedData = true
            }
        }
    }

    //
    //#pragma mark Helper Methods
    //
    private func showSearchTableView(with contacts: [ContactPickerModelProtocol], queryString: String) {
        defer {
            self.searchTableViewController?.queryString = queryString
            self.searchTableViewController?.filteredContacts = contacts
        }
        guard self.searchTableViewController == nil else { return }
        self.searchTableViewController = self.createSearchTableViewController()
        self.searchTableViewController?.modalPresentationStyle = .popover
        self.searchTableViewController?.popoverPresentationController?.delegate = self
        self.searchTableViewController?.preferredContentSize = CGSize(width: Double.infinity, height: Double.infinity)

        self.delegate?.present(self.searchTableViewController!, animated: true, completion: nil)
        self.delegate?.didShowFilteredContactsForContactPicker(contactPicker: self)
    }
    
    internal func hideSearchTableView() {
        guard let _ = self.searchTableViewController else { return }
        self.searchTableViewController?.dismiss(animated: true) {
            self.searchTableViewController = nil
        }

        self.delegate?.didHideFilteredContactsForContactPicker(contactPicker: self)
    }
    
    private var frameForContactSearch: CGRect {
        guard let superview = self.delegate?.view, let window = superview.window else {
            return .zero
        }
        
        var topLine = self.convert(CGPoint.zero, to: window)
        topLine.y += self.frame.size.height
        let size = CGSize(width: window.bounds.width, height: window.bounds.size.height - self.keyboardFrame.size.height - topLine.y)
        let intersection = CGRect(origin: .zero, size: size).intersection(superview.frame.insetBy(dx: 0, dy: -1 * window.frame.height))
        return CGRect(origin: topLine, size: intersection.size)
    }
}

extension ContactPicker : UIPopoverPresentationControllerDelegate {
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.sourceView = self
        popoverPresentationController.sourceRect = self.bounds
        popoverPresentationController.canOverlapSourceViewRect = false
        popoverPresentationController.popoverBackgroundViewClass = NoMarginsPopoverBackgroundView.self
    }
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        self.searchTableViewController = nil
    }
    
    final class NoMarginsPopoverBackgroundView: UIPopoverBackgroundView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.layer.shadowColor = UIColor.clear.cgColor
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override var arrowOffset: CGFloat {
            get { return 0.0 }
            set { }
        }
        
        override var arrowDirection: UIPopoverArrowDirection {
            get { return [] }
            set { }
        }
        
        override class func contentViewInsets() -> UIEdgeInsets {
            return .init(top: 0, left: -10, bottom: -10, right: -10)
        }
        
        override class func arrowBase() -> CGFloat {
            return 0.0
        }
        
        override class func arrowHeight() -> CGFloat {
            return 0.0
        }
    }
}

//
//#pragma mark - ContactCollectionViewDelegate
//
extension ContactPicker : ContactCollectionViewDelegate {

    internal func collectionContactCell(lockCheck model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?) {
        self.delegate?.collectionContactCell(lockCheck: model, progress: progress) { (image, type) in
            complete?(image, type)
            self.contactCollectionView.performBatchUpdates({
                self.layoutIfNeeded()
            }) { (finished) in
                self.delegate?.finishLockCheck()
            }
        }        
    }
    
    func checkMails(in contactGroup: ContactGroupVO, progress: () -> Void, complete: LockCheckComplete?) {
        self.delegate?.checkMails(in: contactGroup, progress: progress, complete: { (image, type) in
            complete?(image, type)
            self.contactCollectionView.performBatchUpdates({
                self.layoutIfNeeded()
            }) { (finished) in
                self.delegate?.finishLockCheck()
            }
        })
    }
    
    internal func collectionView(at: UICollectionView?, willChangeContentSizeTo newSize: CGSize) {
        if !__CGSizeEqualToSize(self.contactCollectionViewContentSize, newSize) {
            self.contactCollectionViewContentSize = newSize
            self.delegate?.contactPicker(contactPicker: self, didUpdateContentHeightTo: self.currentContentHeight)
        }
    }
    
    internal func collectionView(at: ContactCollectionView, entryTextDidChange text: String) {
        guard text != " " else {
            self.hideSearchTableView()
            return
        }
        
        self.contactCollectionView.collectionViewLayout.invalidateLayout()
        self.contactCollectionView.performBatchUpdates( self.layoutIfNeeded ) { (finished) in
            self.contactCollectionView.setFocusOnEntry()
        }
        
        let searchString = text.trimmingCharacters(in: NSCharacterSet.whitespaces)
        let predicate : NSPredicate!
        
        if let hasCustom = self.delegate?.useCustomFilter(), hasCustom == true {
            predicate = self.delegate?.customFilterPredicate(searchString: searchString)
        } else if self.allowsCompletionOfSelectedContacts {
            predicate = NSPredicate(format: "contactTitle contains[cd] %@",
                                    searchString)
        } else {
            predicate = NSPredicate(format: "contactTitle contains[cd] %@ && !SELF IN %@",
                                    searchString,
                                    self.contactCollectionView.selectedContacts)
        }
        
        let filteredContacts = self.contacts.filter { predicate.evaluate(with: $0) }
        if self.hideWhenNoResult && filteredContacts.isEmpty {
            self.hideSearchTableView()
        } else {
            self.showSearchTableView(with: filteredContacts, queryString: searchString)
        }
    }
    
    internal func collectionView(at: ContactCollectionView, didEnterCustom text: String, needFocus focus: Bool) {
        self.delegate?.contactPicker(contactPicker: self, didEnterCustomText: text, needFocus: focus)
        self.hideSearchTableView()
    }
    
    internal func collectionView(at: ContactCollectionView, didSelect contact: ContactPickerModelProtocol) {
        self.delegate?.collectionView(at: contactCollectionView, didSelect: contact)
    }
    
    internal func collectionView(at: ContactCollectionView, didSelect contact: ContactPickerModelProtocol, callback: @escaping (([DraftEmailData]) -> Void)) {
        self.delegate?.collectionView(at: contactCollectionView,
                                      didSelect: contact,
                                      callback: callback)
    }
    
    internal func collectionView(at: ContactCollectionView, didAdd contact: ContactPickerModelProtocol) {
        self.delegate?.collectionView(at: contactCollectionView, didAdd: contact)
    }
    
    internal func collectionView(at: ContactCollectionView, didRemove contact: ContactPickerModelProtocol) {
        self.delegate?.collectionView(at: contactCollectionView, didRemove: contact)
    }
    
    internal func collectionView(at: ContactCollectionView, pasted text: String, needFocus focus: Bool) {
        self.delegate?.contactPicker(picker: self, pasted: text, needFocus: focus)
    }
}
