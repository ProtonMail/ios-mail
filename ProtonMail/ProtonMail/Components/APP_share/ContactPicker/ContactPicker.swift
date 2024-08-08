//
//  ContactPicker.swift
//  Proton Mail - Created on 4/26/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCoreFoundations
import ProtonCoreUIFoundations
import UIKit

protocol ContactPickerDataSource: NSObjectProtocol {
    // optional
    func contactModelsForContactPicker(contactPickerView: ContactPicker) -> [ContactPickerModelProtocol]
    func selectedContactModelsForContactPicker(contactPickerView: ContactPicker) -> [ContactPickerModelProtocol]
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
    func showContactMenu(contact: ContactPickerModelProtocol, contactPicker: ContactPicker)
}

class ContactPicker: UIView, AccessibleView {
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
            addToSelectedContacts(model: model) { [weak self] in
                self?.contactCollectionView.scrollToEntryAnimated(animated: true, onComplete: nil)
            }
        }
        return controller
    }

    internal weak var delegate: (ContactPickerDelegate & UIViewController)?
    internal weak var datasource: ContactPickerDataSource?

    private var _prompt: String = ContactPickerDefined.kPrompt
    private var _maxVisibleRows: CGFloat = ContactPickerDefined.kMaxVisibleRows
    private var allowsCompletionOfSelectedContacts: Bool = true
    private var _enabled: Bool = true
    private var hideWhenNoResult: Bool = false

    private var contacts: [ContactPickerModelProtocol] {
        return self.datasource?.contactModelsForContactPicker(contactPickerView: self) ?? [ContactPickerModelProtocol]()
    }

    internal var contactCollectionView: ContactCollectionView!
    private var promptLabel: UILabel!
    private var grayLine: UIView!

    private var contactCollectionViewContentSize: CGSize = CGSize.zero
    private var hasLoadedData: Bool = false

    internal var cellHeight: Int {
        get {
            return self.contactCollectionView.cellHeight
        }
        set {
            self.contactCollectionView.cellHeight = newValue
            self.contactCollectionView.collectionViewLayout.invalidateLayout()
        }
    }

    internal var contactsSelected: [ContactPickerModelProtocol] {
        get {
            return self.contactCollectionView.selectedContacts
        }
    }

    /// This flag controls if the component will extend its height to show all addresses
    var shouldExtendToShowAllContact: Bool = false

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

    private func setup() {
        self._prompt = ContactPickerDefined.kPrompt
        self.setupPromptLabel()
        self.setupContactCollectionView()
        self.setupGrayLine()

        self.maxVisibleRows = ContactPickerDefined.kMaxVisibleRows

        self.allowsCompletionOfSelectedContacts = true
        self.translatesAutoresizingMaskIntoConstraints = false
        self.clipsToBounds = true

        self.enabled = true
        self.hideWhenNoResult = true
        generateAccessibilityIdentifiers()
        observePreferredContentSizeChanged()
    }

    private func observePreferredContentSizeChanged() {
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
    }

    private func setupPromptLabel() {
        guard self.promptLabel == nil else { return }
        self.promptLabel = UILabel()
        promptLabel.set(text: nil,
                        preferredFont: .subheadline,
                        textColor: ColorProvider.TextWeak)
        self.promptLabel.translatesAutoresizingMaskIntoConstraints = false
        self.promptLabel.accessibilityTraits = .staticText
        self.addSubview(self.promptLabel)
        [
            self.promptLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            self.promptLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 14)
        ].activate()
        self.promptLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.becomeFirstResponder))
        self.promptLabel.addGestureRecognizer(tap)
    }

    private func setupContactCollectionView() {
        guard self.contactCollectionView == nil else { return }
        let contactCollectionView = ContactCollectionView.contactCollectionViewWithFrame(frame: self.bounds)
        contactCollectionView.showPrompt = false
        contactCollectionView.contactDelegate = self
        contactCollectionView.clipsToBounds = true
        contactCollectionView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contactCollectionView)

        self.contactCollectionView = contactCollectionView

        [
            self.contactCollectionView.topAnchor.constraint(equalTo: self.topAnchor, constant: 11),
            self.contactCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            self.contactCollectionView.leadingAnchor.constraint(equalTo: self.promptLabel.trailingAnchor, constant: 8),
            self.contactCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -35)
        ].activate()
    }

    private func setupGrayLine() {
        self.grayLine = UIView(frame: .zero)
        self.grayLine.backgroundColor = ColorProvider.SeparatorNorm
        self.grayLine.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.grayLine)

        [
            self.grayLine.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.grayLine.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.grayLine.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.grayLine.heightAnchor.constraint(equalToConstant: 1)
        ].activate()
    }

    @objc
    private func preferredContentSizeChanged() {
        // The following elements can't reflect font size changed automatically
        // Reset font when event happened
        promptLabel.font = .preferredFont(forTextStyle: .subheadline)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    //
    // #pragma mark - Keyboard Notification Handling
    //

    /// Reloads the list of contacts only if there is a query string already set. Call this function if more contacts are
    /// available to be listed in the picker.
    func reloadContactsList() {
        guard let query = searchTableViewController?.queryString else {
            return
        }
        // this forces to read the list of contacts again
        let filteredContacts = self.filteredContacts(by: query)
        searchTableViewController?.filteredContacts = filteredContacts
    }

    internal func reloadData() {
        self.contactCollectionView.selectedContacts.removeAll()

        if let selected = self.datasource?.selectedContactModelsForContactPicker(contactPickerView: self) {
             self.contactCollectionView.selectedContacts.append(contentsOf: selected)
        }

//        self.contactCollectionView.reloadData()

        self.layoutIfNeeded()
        self.contactCollectionView.layoutIfNeeded()
        self.contactCollectionView.scrollToEntryAnimated(animated: false, onComplete: nil)
        self.hideSearchTableView()

        // Show search result
        collectionView(at: self.contactCollectionView, entryTextDidChange: self.contactCollectionView.searchText)
    }

    func reload() {
        self.contactCollectionView.reloadData()
    }

    func removeContact(address: String) {
        self.contactCollectionView.removeContact(address: address)
    }

    func removeContact(contact: ContactPickerModelProtocol) {
        self.contactCollectionView.removeContact(contact: contact)
    }

    func deselectCells() {
        self.contactCollectionView.visibleCells
            .compactMap { $0 as? ContactCollectionViewContactCell }
            .filter { $0.pickerFocused == true }
            .forEach { $0.pickerFocused = false }
    }
    //
    // #pragma mark - Properties
    //
    internal var prompt: String {
        get {
            return self._prompt
        }
        set {
            self._prompt = newValue
            self.promptLabel.text = newValue
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

    internal var currentContentHeight: CGFloat {
        get {
            let minimumHeight: CGFloat = 48.0
            var minimumSizeWithContent = max(CGFloat(self.cellHeight), self.contactCollectionViewContentSize.height)
            minimumSizeWithContent = max(minimumHeight, minimumSizeWithContent)
            let maximumSize = self.maxVisibleRows * CGFloat(self.cellHeight)

            var finalHeight: CGFloat
            if shouldExtendToShowAllContact {
                finalHeight = minimumSizeWithContent
            } else {
                finalHeight = min(minimumSizeWithContent, maximumSize)
            }

            if finalHeight > 48.0 {
                let topPadding: CGFloat = 11.0
                let bottomPadding: CGFloat = 10.0
                finalHeight = finalHeight + topPadding + bottomPadding
            }
            return finalHeight
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

            if !newValue {
                _ = self.resignFirstResponder()
            }
        }
    }

    internal func addToSelectedContacts(model: ContactPickerModelProtocol, needFocus focus: Bool) {
        self.contactCollectionView.addToSelectedContacts(model: model) { [weak self] in
            if focus {
                self?.contactCollectionView.scrollToEntryAnimated(animated: true, onComplete: nil)
                _ = self?.becomeFirstResponder()
            }
        }
    }

    private func addToSelectedContacts(model: ContactPickerModelProtocol, withCompletion completion: ContactPickerComplete?) {
        self.contactCollectionView.addToSelectedContacts(model: model, withCompletion: completion)
    }

    //
    // #pragma mark - UIResponder
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
    // #pragma mark Helper Methods
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

    private func filteredContacts(by query: String) -> [ContactPickerModelProtocol] {
        let predicate: NSPredicate!

        if let hasCustom = self.delegate?.useCustomFilter(), hasCustom == true {
            predicate = self.delegate?.customFilterPredicate(searchString: query)
        } else if self.allowsCompletionOfSelectedContacts {
            predicate = NSPredicate(format: "contactTitle contains[cd] %@",
                                    query)
        } else {
            predicate = NSPredicate(format: "contactTitle contains[cd] %@ && !SELF IN %@",
                                    query,
                                    self.contactCollectionView.selectedContacts)
        }

        let filteredContacts = self.contacts
            .filter { predicate.evaluate(with: $0) }
            .compactMap { $0.copy() as? ContactPickerModelProtocol }
        return filteredContacts
    }
}

extension ContactPicker: UIPopoverPresentationControllerDelegate {
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
// #pragma mark - ContactCollectionViewDelegate
//
extension ContactPicker: ContactCollectionViewDelegate {

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

    func collectionView(at: UICollectionView?, willChangeContentSizeTo newSize: CGSize) {
        guard newSize != contactCollectionViewContentSize else {
            return
        }

        guard newSize.width >= 0, newSize.height >= 0 else {
            PMAssertionFailure("ContactPicker - invalid size: \(newSize)")
            return
        }

        contactCollectionViewContentSize = newSize
        delegate?.contactPicker(contactPicker: self, didUpdateContentHeightTo: currentContentHeight)
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
        let filteredContacts = self.filteredContacts(by: searchString)
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

    func collectionView(at: ContactCollectionView, pasted groupName: String, addresses: [String]) -> Bool {
        let contacts = self.filteredContacts(by: groupName)
        guard contacts.count == 1,
              let group = contacts.first as? ContactGroupVO else { return false }
        group.selectAllEmailFromGroup()
        let selected = group.getSelectedEmailData()
            .filter { addresses.contains($0.email) }
        group.overwriteSelectedEmails(with: selected)
        self.addToSelectedContacts(model: group, needFocus: false)
        return true
    }

    func showContactMenu(contact: ContactPickerModelProtocol) {
        self.delegate?.showContactMenu(contact: contact, contactPicker: self)
    }
}
