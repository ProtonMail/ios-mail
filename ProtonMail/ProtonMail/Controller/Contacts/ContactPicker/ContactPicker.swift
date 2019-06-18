//
//  ContactPicker.swift
//  ProtonMail - Created on 4/26/18.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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

class ContactPicker: UIView, WindowOverlayDelegate {
    private var keyboardFrame: CGRect = .zero
    private var searchWindow: WindowOverlay?
    private var searchTableViewController: ContactSearchTableViewController?
    private func createSearchTableViewController() -> ContactSearchTableViewController {
        let controller = ContactSearchTableViewController()
        controller.tableView.register(UINib.init(nibName: ContactPickerDefined.ContactsTableViewCellName,
                                                 bundle: nil),
                                 forCellReuseIdentifier: ContactPickerDefined.ContactsTableViewCellIdentifier)
        controller.tableView.translatesAutoresizingMaskIntoConstraints = false
        controller.tableView.estimatedRowHeight = 60.0
        controller.tableView.sectionHeaderHeight = 0;
        controller.tableView.sectionFooterHeight = 0;
        controller.tableView.reloadData()
        if #available(iOS 11.0, *) {
            controller.tableView.contentInsetAdjustmentBehavior = .never
        }
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
            self.searchWindow?.frame = self.frameForContactSearch
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
        self.searchWindow?.removeFromSuperview()
        self.searchWindow = nil
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
        self.contactCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(hideSearchTableView),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
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
        self.contactCollectionView.reloadData()
        
        self.layoutIfNeeded()
        self.contactCollectionView.layoutIfNeeded()
        self.contactCollectionView.scrollToEntryAnimated(animated: false, onComplete: nil)
        self.hideSearchTableView()
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
        self.searchWindow = self.searchWindow ?? WindowOverlay(frame: self.frameForContactSearch)
        self.searchWindow?.rootViewController = self.searchTableViewController
        self.searchWindow?.isHidden = false
        self.searchWindow?.windowLevel = UIWindow.Level.normal
        self.searchWindow?.delegate = self

        if #available(iOS 10.0, *) { // iOS 10-12, extension
        #if APP_EXTENSION
            // this line is needed for Share Extension only: extension's UI is presented in private _UIHostedWindow and we should add new window to it's hierarchy explicitly
            self.window?.addSubview(searchWindow!)
            self.searchWindow?.frame = self.frameForContactSearch
        #endif
        } else { // iOS 9, app and extension
            self.window?.addSubview(searchWindow!)
        }
        
        self.delegate?.didShowFilteredContactsForContactPicker(contactPicker: self)
    }

    @objc internal func hideSearchTableView() {
        guard let _ = self.searchTableViewController else { return }
        self.searchTableViewController = nil
        self.searchWindow?.rootViewController = nil
        self.searchWindow?.isHidden = true
        
        if #available(iOS 10.0, *) { // iOS 10-12, app
        #if APP_EXTENSION
            // in extenison window is strongly held by _UIHostedWindow and we can not change that since removeFromSuperview() does not work properly, so we'll just reuse same window all over again
        #else
            // in the app we can re-create new windows many times
            self.searchWindow = nil
        #endif
        } else { // iOS 9, app and extension
            self.searchWindow = nil
        }
        
        self.delegate?.didHideFilteredContactsForContactPicker(contactPicker: self)
    }
    
    private var frameForContactSearch: CGRect {
        guard let window = self.delegate?.view.window else {
            return .zero
        }
        
        var topLine = self.convert(CGPoint.zero, to: window)
        topLine.y += self.frame.size.height
        let size = CGSize(width: window.bounds.width, height: window.bounds.size.height - self.keyboardFrame.size.height - topLine.y)
        return .init(origin: topLine, size: size)
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

protocol WindowOverlayDelegate: class {
    func hideSearchTableView()
    func resignFirstResponder() -> Bool
}
class WindowOverlay: UIWindow {
    weak var delegate: WindowOverlayDelegate?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // point is given in window's coordinates, we're closing it if tapped in area above window (because below window is a keyboard and ios 11 freaks out)
        if !self.isHidden, point.y < 0 {
            let _ = self.delegate?.resignFirstResponder()
            self.delegate?.hideSearchTableView()
        }
        
        return super.hitTest(point, with: event)
    }
}
