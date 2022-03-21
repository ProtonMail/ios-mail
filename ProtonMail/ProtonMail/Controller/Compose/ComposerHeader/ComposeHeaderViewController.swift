//
//  ComposeView.swift
//  ProtonMail - Created on 5/27/15.
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

import Foundation
import Masonry
import ProtonCore_UIFoundations
import UIKit

final class ComposeHeaderViewController: UIViewController, AccessibleView {
    // MARK: - Outlets
    @IBOutlet private(set) var subject: UITextField!
    @IBOutlet private var subjectTopToToContactPicker: NSLayoutConstraint!
    @IBOutlet private var subjectTopToBccContactPicker: NSLayoutConstraint!
    @IBOutlet private var showCcBccButton: UIButton!

    // MARK: - From field
    @IBOutlet private(set) var fromView: UIView!
    @IBOutlet private var fromAddress: UILabel!
    @IBOutlet private var fromPickerButton: UIButton!
    @IBOutlet private var fromLable: UILabel!
    @IBOutlet private var fromGrayView: UIView!
    @IBOutlet private weak var subjectGrayView: UIView!

    @IBOutlet private(set) var toContactPicker: ContactPicker!
    @IBOutlet private(set) var ccContactPicker: ContactPicker!
    @IBOutlet private(set) var bccContactPicker: ContactPicker!
    @IBOutlet private var toContactPickerHeight: NSLayoutConstraint!
    @IBOutlet private var ccContactPickerHeight: NSLayoutConstraint!
    @IBOutlet private var bccContactPickerHeight: NSLayoutConstraint!

    private var height: NSLayoutConstraint!
    private(set) var pickerHeight: CGFloat = 0.0

    @objc
    dynamic var size: CGSize = .zero {
        didSet {
            self.height.constant = size.height
        }
    }

    var hasOutSideEmails: Bool {
        let toHas = toContactPicker.hasOutsideEmails
        if toHas {
            return true
        }

        let ccHas = ccContactPicker.hasOutsideEmails
        if ccHas {
            return true
        }

        let bccHas = bccContactPicker.hasOutsideEmails
        if bccHas {
            return true
        }

        return false
    }

    var hasNonePMEmails: Bool {
        let toHas = toContactPicker.hasNonePM
        if toHas {
            return true
        }

        let ccHas = ccContactPicker.hasNonePM
        if ccHas {
            return true
        }

        let bccHas = bccContactPicker.hasNonePM
        if bccHas {
            return true
        }

        return false
    }

    var hasPGPPinned: Bool {
        let toHas = toContactPicker.hasPGPPinned
        if toHas {
            return true
        }

        let ccHas = ccContactPicker.hasPGPPinned
        if ccHas {
            return true
        }

        let bccHas = bccContactPicker.hasPGPPinned
        if bccHas {
            return true
        }

        return false
    }

    var nonePMEmails: [String] {
        var out: [String] = [String]()
        out.append(contentsOf: toContactPicker.nonePMEmails)
        out.append(contentsOf: ccContactPicker.nonePMEmails)
        out.append(contentsOf: bccContactPicker.nonePMEmails)
        return out
    }

    var pgpEmails: [String] {
        var out: [String] = [String]()
        out.append(contentsOf: toContactPicker.pgpEmails)
        out.append(contentsOf: ccContactPicker.pgpEmails)
        out.append(contentsOf: bccContactPicker.pgpEmails)
        return out
    }

    var allEmails: String {  // email,email,email
        var emails: [String] = []

        let toEmails = toContactPicker.contactList
        if !toEmails.isEmpty {
            emails.append(toEmails)
        }

        let ccEmails = ccContactPicker.contactList
        if !ccEmails.isEmpty {
            emails.append(ccEmails)
        }

        let bccEmails = bccContactPicker.contactList
        if !bccEmails.isEmpty {
            emails.append(bccEmails)
        }
        if emails.isEmpty {
            return ""
        }
        return emails.asCommaSeparatedList(trailingSpace: false)
    }

    var ccContacts: String {
        return ccContactPicker.contactList
    }
    var bccContacts: String {
        return bccContactPicker.contactList
    }
    var toContacts: String {
        return toContactPicker.contactList
    }

    var expirationTimeInterval: TimeInterval = 0

    var hasContent: Bool {// need check body also here
        return !toContacts.isEmpty || !ccContacts.isEmpty || !bccContacts.isEmpty || !subjectTitle.isEmpty
    }

    var subjectTitle: String {
        return subject.text ?? ""
    }
    private var isConnected: Bool?

    // MARK: - Delegate and Datasource
    weak var datasource: ComposeViewDataSource?
    weak var delegate: ComposeViewDelegate?

    // MARK: - Constants
    fileprivate let kDefaultRecipientHeight: Int = 28
    fileprivate let kErrorMessageHeight: CGFloat = 48.0
    fileprivate let kNumberOfColumnsInTimePicker: Int = 2
    fileprivate let kNumberOfDaysInTimePicker: Int = 30
    fileprivate let kNumberOfHoursInTimePicker: Int = 24
    fileprivate let kCcBccContainerViewHeight: CGFloat = 96.0
    fileprivate let kAnimationDuration = 0.25

    //
    fileprivate var isShowingCcBccView: Bool = false
    fileprivate var hasExpirationSchedule: Bool = false

    /// Use this flag to control the email validation action
    var shouldValidateTheEmail = true

    private let internetConnectionStatusProvider = InternetConnectionStatusProvider()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = ColorProvider.BackgroundNorm
        // 184 is default height of header view
        self.height = self.view.heightAnchor.constraint(equalToConstant: 184)
        self.height.priority = .init(999.0)
        self.height.isActive = true

        self.fromLable.attributedText = "\(LocalString._composer_from_label): ".apply(style: .DefaultSmallWeek)
        self.fromPickerButton.tintColor = ColorProvider.IconWeak
        if #available(iOS 14.0, *) {
            self.delegate?.setupComposeFromMenu(for: self.fromPickerButton)
            self.fromPickerButton.addTarget(self, action: #selector(self.clickFromField(_:)), for: .menuActionTriggered)
        }

        self.showCcBccButton.tintColor = ColorProvider.IconWeak
        self.showCcBccButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 7)

        self.configureContactPickerTemplate()

        self.configureContactPicker()
        self.configureSubject()

        self.fromGrayView.backgroundColor = ColorProvider.SeparatorNorm
        self.subjectGrayView.backgroundColor = ColorProvider.SeparatorNorm
        self.view.bringSubviewToFront(showCcBccButton)
        self.view.bringSubviewToFront(subject)
        self.view.sendSubviewToBack(ccContactPicker)
        self.view.sendSubviewToBack(bccContactPicker)

        ccContactPicker.backgroundColor = ColorProvider.BackgroundNorm
        bccContactPicker.backgroundColor = ColorProvider.BackgroundNorm
        toContactPicker.backgroundColor = ColorProvider.BackgroundNorm

        // accessibility
        self.view.isAccessibilityElement = false
        self.accessibilityElements = [ self.fromPickerButton!,
                                       self.toContactPicker!,
                                       self.ccContactPicker!, self.bccContactPicker!,
                                       self.subject!
        ]
        generateAccessibilityIdentifiers()
        if let showCcBcc = self.datasource?.ccBccIsShownInitially(),
           showCcBcc {
            self.setShowingCcBccView(to: showCcBcc)
            self.showCcBccButton.isHidden = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observeInternetConnectionStatus()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.datasource?.ccBccIsShownInitially() ?? false ||
            self.ccContactPicker.alpha == 1 {
            self.setShowingCcBccView(to: true)
        } else {
            self.view.removeConstraint(self.subjectTopToBccContactPicker)
            self.view.addConstraint(self.subjectTopToToContactPicker)
        }
        self.notifyViewSize( false )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        internetConnectionStatusProvider.stopInternetConnectionStatusObservation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.datasource?.ccBccIsShownInitially() == false && isShowingCcBccView == false {
            if view.constraints.contains(self.subjectTopToBccContactPicker) {
                self.view.removeConstraint(self.subjectTopToBccContactPicker)
            }
            if !view.constraints.contains(self.subjectTopToToContactPicker) {
                self.view.addConstraint(self.subjectTopToToContactPicker)
            }
            self.updateViewSize()
        }
    }

    func reloadPicker() {
        self.toContactPicker.reload()
        self.ccContactPicker.reload()
        self.bccContactPicker.reload()
    }

    @IBAction func contactPlusButtonTapped(_ sender: UIButton) {
        self.plusButtonHandle()
        self.notifyViewSize(true)
    }

    @IBAction func fromPickerAction(_ sender: AnyObject) {
        self.delegate?.composeViewPickFrom(self)
    }

    func updateFromValue (_ email: String, pickerEnabled: Bool) {
        fromAddress.attributedText = email.apply(style: FontManager.DefaultSmall.lineBreakMode(.byTruncatingMiddle))
        fromPickerButton.isEnabled = pickerEnabled
    }

    @objc
    func clickFromField(_ sender: Any) {
        self.view.endEditing(true)
        _ = self.toContactPicker.becomeFirstResponder()
        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
            _ = self.toContactPicker.resignFirstResponder()
        })
    }

    // MARK: - - Private Methods
    fileprivate func includeButtonBorder(_ view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor = ColorProvider.SeparatorNorm.cgColor
    }

    fileprivate func configureContactPickerTemplate() {
        ContactCollectionViewContactCell.appearance().tintColor = ColorProvider.BrandNorm
        ContactCollectionViewContactCell.appearance().font = Fonts.h5.regular
        ContactCollectionViewPromptCell.appearance().font = Fonts.h5.regular
        ContactCollectionViewEntryCell.appearance().font = Fonts.h5.regular
    }

    ///
    internal func notifyViewSize(_ animation: Bool) {
        UIView.animate(withDuration: animation ? self.kAnimationDuration : 0, delay: 0, options: UIView.AnimationOptions(), animations: {
            self.updateViewSize()
            self.size = CGSize(width: self.view.frame.width, height: self.subject.frame.origin.y + self.subject.frame.height + self.pickerHeight)
            self.delegate?.ComposeViewDidSizeChanged(self.size, showPicker: self.pickerHeight > 0.0)
            }, completion: nil)
    }

    internal func configureSubject() {
        let paddingView = UIView(frame: .zero)
        let label = UILabel(frame: .zero)
        label.attributedText = "\(LocalString._composer_subject_placeholder):".apply(style: .DefaultSmallWeek)
        label.sizeToFit()
        label.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.focusSubject))
        label.addGestureRecognizer(tap)
        paddingView.addSubview(label)
        [
            label.leadingAnchor.constraint(equalTo: paddingView.leadingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: paddingView.topAnchor, constant: 13),
            label.widthAnchor.constraint(equalToConstant: label.frame.size.width),
            paddingView.heightAnchor.constraint(equalToConstant: 48),
            paddingView.widthAnchor.constraint(equalToConstant: label.frame.size.width + 24)
        ].activate()
        paddingView.layoutIfNeeded()
        self.subject.leftView = paddingView
        self.subject.leftViewMode = UITextField.ViewMode.always
        self.subject.autocapitalizationType = .sentences
        self.subject.delegate = self
        self.subject.textColor = ColorProvider.TextNorm

        self.view.removeConstraint(self.subjectTopToBccContactPicker)
        self.view.addConstraint(self.subjectTopToToContactPicker)
    }

    internal func setShowingCcBccView(to show: Bool) {
        isShowingCcBccView = show
        if show {
            UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
                self.ccContactPicker.alpha = 1.0
                self.bccContactPicker.alpha = 1.0
                self.view.addConstraint(self.subjectTopToBccContactPicker)
                self.view.removeConstraint(self.subjectTopToToContactPicker)
                self.showCcBccButton.setImage(UIImage(named: "arrow_up"), for: .normal )
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
                self.view.addConstraint(self.subjectTopToToContactPicker)
                self.view.removeConstraint(self.subjectTopToBccContactPicker)
                self.ccContactPicker.alpha = 0.0
                self.bccContactPicker.alpha = 0.0
                self.showCcBccButton.setImage(UIImage(named: "arrow_down"), for: .normal )
                self.view.layoutIfNeeded()
            })

        }
    }

    internal func plusButtonHandle() {
        self.setShowingCcBccView(to: !isShowingCcBccView)
    }

    fileprivate func updateViewSize() {
        let size = CGSize(width: self.view.frame.width, height: self.subject.frame.origin.y + self.subject.frame.height)
        if self.size != size {
            self.size = size
        }
    }

    private func configureContactPicker() {
        toContactPicker.cellHeight = self.kDefaultRecipientHeight
        toContactPicker.datasource = self
        toContactPicker.delegate = self
        toContactPicker.shouldExtendToShowAllContact = true

        ccContactPicker.cellHeight = self.kDefaultRecipientHeight
        ccContactPicker.datasource = self
        ccContactPicker.delegate = self
        ccContactPicker.shouldExtendToShowAllContact = true
        ccContactPicker.alpha = 0

        bccContactPicker.cellHeight = self.kDefaultRecipientHeight
        bccContactPicker.datasource = self
        bccContactPicker.delegate = self
        bccContactPicker.shouldExtendToShowAllContact = true
        bccContactPicker.alpha = 0
    }

    private func checkShowCcBccButton() {
        let count = self.ccContactPicker.contactsSelected.count + self.bccContactPicker.contactsSelected.count
        self.showCcBccButton.isHidden = count != 0
    }

    fileprivate func updateContactPickerHeight(_ contactPicker: ContactPicker, newHeight: CGFloat) {
        if contactPicker == self.toContactPicker {
            self.toContactPickerHeight.constant = newHeight
        } else if contactPicker == self.ccContactPicker {
            self.ccContactPickerHeight.constant = newHeight
        } else if contactPicker == self.bccContactPicker {
            self.bccContactPickerHeight.constant = newHeight
        }
    }

    private func observeInternetConnectionStatus() {
        internetConnectionStatusProvider.registerConnectionStatus { [weak self] status in
            guard status.isConnected else {
                self?.isConnected = false
                return
            }
            if let previousStatus = self?.isConnected,
               previousStatus == status.isConnected {
                // In card modal
                // even slightly drag down can trigger viewWillDisappear and view willAppear
                // Validate mail addresses until the status really changed
                return
            }
            self?.isConnected = status.isConnected
            self?.checkEmails()
        }
    }

    private func checkEmails() {
        self.ccContactPicker.contactCollectionView.reloadData()
        self.bccContactPicker.contactCollectionView.reloadData()
        self.toContactPicker.contactCollectionView.reloadData()
    }

    @objc
    private func focusSubject() {
        self.subject.becomeFirstResponder()
    }
}

// MARK: - ContactPickerDataSource
extension ComposeHeaderViewController: ContactPickerDataSource {

    func picker(contactPicker: ContactPicker, model: ContactPickerModelProtocol, progress: () -> Void, complete: ((UIImage?, Int) -> Void)?) {
        self.delegate?.lockerCheck(model: model, progress: progress, complete: complete)
    }

    func contactModelsForContactPicker(contactPickerView: ContactPicker) -> [ContactPickerModelProtocol] {
        if contactPickerView == toContactPicker {
            contactPickerView.prompt = "\(LocalString._composer_to_label):"
        } else if contactPickerView == ccContactPicker {
            contactPickerView.prompt = "\(LocalString._composer_cc_label):"
        } else if contactPickerView == bccContactPicker {
            contactPickerView.prompt = "\(LocalString._composer_bcc_label):"
        }
        return self.datasource?.composeViewContactsModelForPicker(self, picker: contactPickerView) ?? [ContactPickerModelProtocol]()
    }

    func selectedContactModelsForContactPicker(contactPickerView: ContactPicker) -> [ContactPickerModelProtocol] {
        return self.datasource?.composeViewSelectedContactsForPicker(self, picker: contactPickerView) ?? [ContactPickerModelProtocol]()
    }
}

// MARK: - ContactPickerDelegate
extension ComposeHeaderViewController: ContactPickerDelegate {
    func finishLockCheck() {
        self.notifyViewSize(false)
    }

    func contactPicker(contactPicker: ContactPicker, didUpdateContentHeightTo newHeight: CGFloat) {
        self.updateContactPickerHeight(contactPicker, newHeight: newHeight)
    }

    func didShowFilteredContactsForContactPicker(contactPicker: ContactPicker) {
        self.delegate?.composeViewWillPresentSubview()
    }

    func didHideFilteredContactsForContactPicker(contactPicker: ContactPicker) {
        self.delegate?.composeViewWillDismissSubview()
        self.view.sendSubviewToBack(contactPicker)
        if contactPicker.frame.size.height > contactPicker.currentContentHeight {
            self.updateContactPickerHeight(contactPicker, newHeight: contactPicker.currentContentHeight)
        }
        self.pickerHeight = 0
        self.notifyViewSize(false)
    }

    func contactPicker(contactPicker: ContactPicker, didEnterCustomText text: String, needFocus focus: Bool) {
        if self.shouldValidateTheEmail {
            let customContact = ContactVO(id: "", name: text, email: text)
            contactPicker.addToSelectedContacts(model: customContact, needFocus: focus)
        }
    }

    func contactPicker(picker: ContactPicker, pasted text: String, needFocus focus: Bool) {
        if text.contains(check: ",") {
            let separatorSet = CharacterSet(charactersIn: ",;")
            let cusTexts = text.components(separatedBy: separatorSet)
            // let cusTexts = text.split(separator: ",")
            for cusText in cusTexts {
                let trimmed = cusText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    let customContact = ContactVO(id: "", name: trimmed, email: trimmed)
                    picker.addToSelectedContacts(model: customContact, needFocus: focus)
                }
            }
        } else if text.contains(check: ";") {
            let separatorSet = CharacterSet(charactersIn: ",;")
            let cusTexts = text.components(separatedBy: separatorSet)
            // let cusTexts = text.split(separator: ";")
            for cusText in cusTexts {
                let trimmed = cusText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    let customContact = ContactVO(id: "", name: trimmed, email: trimmed)
                    picker.addToSelectedContacts(model: customContact, needFocus: focus)
                }
            }
        } else {
            let customContact = ContactVO(id: "", name: text, email: text)
            picker.addToSelectedContacts(model: customContact, needFocus: focus)
        }
    }

    func useCustomFilter() -> Bool {
        return true
    }

    func customFilterPredicate(searchString: String) -> NSPredicate {
        return NSPredicate(format: "contactTitle CONTAINS[cd] %@ or contactSubtitle CONTAINS[cd] %@", argumentArray: [searchString, searchString])
    }

    func collectionView(at: UICollectionView?, willChangeContentSizeTo newSize: CGSize) {

    }

    func collectionView(at: ContactCollectionView, entryTextDidChange text: String) {

    }

    func collectionView(at: ContactCollectionView, didEnterCustom text: String, needFocus focus: Bool) {

    }

    func collectionView(at: ContactCollectionView, didSelect contact: ContactPickerModelProtocol) {

    }

    func collectionView(at: ContactCollectionView,
                        didSelect contact: ContactPickerModelProtocol,
                        callback: @escaping (([DraftEmailData]) -> Void)) {
        // if the selected type is contact group
        // we present the sub-selection view
        if let contactGroup = contact as? ContactGroupVO {
            self.delegate?.composeViewDidTapContactGroupSubSelection(self,
                                                                     contactGroup: contactGroup,
                                                                     callback: callback)
        }
    }

    func collectionView(at: ContactCollectionView, didAdd contact: ContactPickerModelProtocol) {
        let contactPicker = contactPickerForContactCollectionView(at)
        self.notifyViewSize(true)
        self.delegate?.composeView(self, didAddContact: contact, toPicker: contactPicker)
        self.checkShowCcBccButton()
    }

    func collectionView(at: ContactCollectionView, didRemove contact: ContactPickerModelProtocol) {
        let contactPicker = contactPickerForContactCollectionView(at)
        self.notifyViewSize(true)
        self.delegate?.composeView(self, didRemoveContact: contact, fromPicker: contactPicker)
        self.checkShowCcBccButton()
    }

    func collectionView(at: ContactCollectionView, pasted text: String, needFocus focus: Bool) {

    }

    func collectionView(at: ContactCollectionView, pasted groupName: String, addresses: [String]) -> Bool { return false }

    func collectionContactCell(lockCheck model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?) {
        self.delegate?.lockerCheck(model: model, progress: progress, complete: complete)
    }

    func checkMails(in contactGroup: ContactGroupVO, progress: () -> Void, complete: LockCheckComplete?) {
        self.delegate?.checkMails(in: contactGroup, progress: progress, complete: complete)
    }

    // MARK: Private delegate helper methods
    fileprivate func contactPickerForContactCollectionView(_ contactCollectionView: ContactCollectionView) -> ContactPicker {
        var contactPicker: ContactPicker = toContactPicker
        if contactCollectionView == toContactPicker.contactCollectionView {
            contactPicker = toContactPicker
        } else if contactCollectionView == ccContactPicker.contactCollectionView {
            contactPicker = ccContactPicker
        } else if contactCollectionView == bccContactPicker.contactCollectionView {
            contactPicker = bccContactPicker
        }
        return contactPicker
    }

    func showContactMenu(contact: ContactPickerModelProtocol) {
        // Don't need to implement
    }

    func showContactMenu(contact: ContactPickerModelProtocol, contactPicker: ContactPicker) {
        self.subject.becomeFirstResponder()
        self.subject.endEditing(true)
        self.view.endEditing(true)
        if let contact = contact as? ContactVO {
            self.showContactMenu(contact: contact, contactPicker: contactPicker)
        } else if let group = contact as? ContactGroupVO {
            self.showContactMenu(contact: group, contactPicker: contactPicker)
        }
    }

    private func showContactMenu(contact: ContactVO, contactPicker: ContactPicker) {
        guard let parent = self.parent?.navigationController,
              let address = contact.displayEmail else { return }
        let copy = PMActionSheetPlainItem(title: LocalString._general_copy, icon: nil) { _ in
            UIPasteboard.general.string = address
            contactPicker.deselectCells()
        }
        let cut = PMActionSheetPlainItem(title: LocalString._general_cut, icon: nil) { _ in
            UIPasteboard.general.string = address
            contactPicker.removeContact(address: address)
            contactPicker.deselectCells()
        }
        let group = PMActionSheetItemGroup(items: [copy, cut], style: .clickable)
        let header = PMActionSheetHeaderView(title: address, subtitle: nil, leftItem: nil, rightItem: nil)
        let sheet = PMActionSheet(headerView: header, itemGroups: [group])
        sheet.eventsListener = self
        sheet.presentAt(parent, animated: true)
    }

    private func showContactMenu(contact: ContactGroupVO, contactPicker: ContactPicker) {
        let name = contact.contactTitle
        let selected = contact.getSelectedEmailAddresses()
        guard let parent = self.parent?.navigationController,
              let value = ["\(name)": selected].toString() else {
            return
        }

        let copy = PMActionSheetPlainItem(title: LocalString._general_copy, icon: nil) { _ in
            UIPasteboard.general.string = value
        }
        let cut = PMActionSheetPlainItem(title: LocalString._general_cut, icon: nil) { _ in
            UIPasteboard.general.string = value
            contactPicker.removeContact(contact: contact)
        }
        let group = PMActionSheetItemGroup(items: [copy, cut], style: .clickable)
        let header = PMActionSheetHeaderView(title: name, subtitle: nil, leftItem: nil, rightItem: nil)
        let sheet = PMActionSheet(headerView: header, itemGroups: [group])
        sheet.eventsListener = self
        sheet.presentAt(parent, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension ComposeHeaderViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == self.subject, string.count > 1 else { return true }
        if var text = textField.text,
           let textRange = Range(range, in: text) {
            text.replaceSubrange(textRange, with: string)
            if text.hasPrefix(" ") || text.hasSuffix(" ") {
                // Trigger trim function when needed
                // Or this could cause infinite loop, MAILIOS-1410
                textField.text = text.trim()
                return false
            }
        }
        return true
    }
}

// MARK: - ContactPicker extension
extension ContactPicker {
    // TODO: contact group email expansion
    var contactList: String {
        var contactList = ""
        let contactsSelected = NSArray(array: self.contactsSelected)
        let contacts = contactsSelected.compactMap { (contact) -> String? in
            return (contact as? ContactVO)?.email
        }
        contactList = contacts.asCommaSeparatedList(trailingSpace: false)
        return contactList
    }

    // TODO:: the hard code at here should be moved to enum / struture
    var hasOutsideEmails: Bool {
        let contactsSelected = NSArray(array: self.contactsSelected)
        if let contacts = contactsSelected.value(forKey: ContactVO.Attributes.email) as? [String] {
            for contact in contacts {
                if contact.lowercased().range(of: "@protonmail.ch") == nil && contact.lowercased().range(of: "@protonmail.com") == nil && contact.lowercased().range(of: "@pm.me") == nil {
                    return true
                }
            }
        }
        return false
    }

    var hasPGPPinned: Bool {
        for contact in self.contactsSelected {
            if contact.hasPGPPined {
                return true
            }
        }
        return false
    }

    var hasNonePM: Bool {
        for contact in self.contactsSelected {
            if contact.hasNonePM {
                return true
            }
        }
        return false
    }

    var pgpEmails: [String] {
        var out: [String] = [String]()
        for contact in self.contactsSelected {
            if let group = contact as? ContactGroupVO, group.hasPGPPined {
                out += group.pgpEmails
            } else if contact.hasPGPPined, let email = contact.displayEmail {
                out.append(email)
            }
        }
        return out
    }

    var nonePMEmails: [String] {
        var out: [String] = [String]()
        for contact in self.contactsSelected {
            if let group = contact as? ContactGroupVO, group.hasNonePM {
                out += group.nonePMEmails
            } else if contact.hasNonePM, let email = contact.displayEmail {
                out.append(email)
            }
        }
        return out
    }
}

extension ComposeHeaderViewController: PMActionSheetEventsListener {
    func willPresent() { }

    func willDismiss() {
        self.toContactPicker.deselectCells()
        self.ccContactPicker.deselectCells()
        self.bccContactPicker.deselectCells()
    }

    func didDismiss() {}
}
