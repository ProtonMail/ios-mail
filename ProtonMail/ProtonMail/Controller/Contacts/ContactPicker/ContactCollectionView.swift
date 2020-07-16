//
//  ContactCollectionView.swift
//  ProtonMail - Created on 4/27/18.
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

//Complete
typealias ContactPickerComplete = (() -> Void)

protocol ContactCollectionViewDelegate : NSObjectProtocol, ContactCollectionViewContactCellDelegate {
    func collectionView(at: UICollectionView?, willChangeContentSizeTo newSize: CGSize)
    func collectionView(at: ContactCollectionView, entryTextDidChange text: String)
    func collectionView(at: ContactCollectionView, didEnterCustom text: String, needFocus focus: Bool)
    func collectionView(at: ContactCollectionView, didSelect contact: ContactPickerModelProtocol)
    func collectionView(at: ContactCollectionView, didSelect contact: ContactPickerModelProtocol, callback: @escaping (([DraftEmailData]) -> Void))
    
    func collectionView(at: ContactCollectionView, didAdd contact: ContactPickerModelProtocol)
    func collectionView(at: ContactCollectionView, didRemove contact: ContactPickerModelProtocol)
    func collectionView(at: ContactCollectionView, pasted text: String, needFocus focus: Bool)
}

enum ContactCollectionViewSection : Int {
    case prompt
    case contact
    case entry
}

class ContactCollectionView: UICollectionView, UICollectionViewDataSource {
    
    var _prompt : String!
    var _allowsTextInput: Bool = true
    var _showPrompt: Bool = true
    var searchText: String!
    
    var cellHeight: Int = ContactPickerDefined.ROW_HEIGHT
    var selectedContacts: [ContactPickerModelProtocol]!
    
    weak var contactDelegate: ContactCollectionViewDelegate?
    
    var prototypeCell: ContactCollectionViewContactCell!
    var promptCell: ContactCollectionViewPromptCell?
    
    class func contactCollectionViewWithFrame(frame: CGRect) -> ContactCollectionView {
        let layout = ContactCollectionViewFlowLayout()
        return ContactCollectionView(frame: frame, collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.setup()
    }
    
    func setFrame(frame: CGRect) {
        let origWidth = self.frame.width
        self.collectionViewLayout.invalidateLayout()
        self.frame = frame
        self.handleWidthChangeFrom(oldWidth: origWidth, to: frame.width)
    }
    
    func setup() {
        self.selectedContacts = [ContactPickerModelProtocol]()
        
        self.cellHeight = ContactPickerDefined.kCellHeight
        self._prompt = ContactPickerDefined.kPrompt
        self.searchText = ContactPickerDefined.kDefaultEntryText
        self.allowsTextInput = true
        self._showPrompt = true
        
        if let layout = self.collectionViewLayout as? ContactCollectionViewFlowLayout {
            layout.minimumInteritemSpacing = 0 //5
            layout.minimumLineSpacing = 0 // 1
            layout.sectionInset = UIEdgeInsets.init(top: 0, left: 6, bottom: 0, right: 6)
        }
        
        self.prototypeCell = ContactCollectionViewContactCell()
        
        self.allowsMultipleSelection = false
        self.allowsSelection = true
        self.backgroundColor = UIColor(hexColorCode: "#FFFFFF") //UIColorFromRGB(0xFCFEFF)
        
        //        self.register(ContactCollectionViewContactCell.self, forCellWithReuseIdentifier: "ContactCell")
        self.register(UINib.init(nibName: "ContactCollectionViewContactCell", bundle: nil),
                      forCellWithReuseIdentifier: "ContactCell")
        
        self.register(ContactCollectionViewEntryCell.self, forCellWithReuseIdentifier:"ContactEntryCell")
        self.register(ContactCollectionViewPromptCell.self, forCellWithReuseIdentifier:"ContactPromptCell")
        
        self.dataSource = self
        self.delegate = self
    }
    
    override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            let origWidth = super.bounds.size.width
            self.collectionViewLayout.invalidateLayout()
            super.bounds = newValue
            self.handleWidthChangeFrom(oldWidth: origWidth, to: newValue.width)
        }
    }
    
    //
    func handleWidthChangeFrom(oldWidth : CGFloat, to newWidth: CGFloat) {
        if oldWidth != newWidth {
            self.forceRelayout()
        }
    }
    
    override func reloadData() {
        super.reloadData()
        self.collectionViewLayout.invalidateLayout()
        // FIXME: next like with forceRelayout() sometimes causes cycle of relayouts because ContactCollectionViewFlowLayout then calls reloadData() again and the app crashes. It happens 100% when restoring saved state of Composer. Check if it's safe to remove
        // self.forceRelayout()
    }
    
    func forceRelayout() {
        // Use the flow layout call chain to relayout. This is also called by the performBatchUpdates call,
        // but that was leading to an untimely access to the layout object after it had be dealloc'd during
        // view destruction. It seems some event was being queued up after the dealloc had been scheduled.
        if let layout = self.collectionViewLayout as? ContactCollectionViewFlowLayout {
            layout.finalizeCollectionViewUpdates()
        }
    }
    
    
    //
    //#pragma mark - Properties
    //
    var maxContentWidth : CGFloat {
        get {
            //TODO:: remove ! later
            let sectionInset = (self.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset
            return self.frame.size.width - sectionInset.left - sectionInset.right
        }
    }
    
    var allowsTextInput : Bool {
        get {
            return self._allowsTextInput
        }
        set {
            self._allowsTextInput = newValue
        }
    }
    
    // this should return ?
    var entryCellIndexPath : IndexPath {
        let r = self.selectedContacts.count + (self.showPrompt ? 1 : 0)
        return IndexPath(row: r, section: 0)
    }
    //
    var showPrompt : Bool {
        get {
            return self._showPrompt
        }
        set {
            _showPrompt = newValue
        }
    }
    
    var prompt : String {
        get {
            return _prompt
        }
        set {
            self._prompt = newValue
        }
    }
    
    //
    //#pragma mark - UIResponder
    //
    
    // Important to return YES here if we want to become the first responder after a child (i.e., entry UITextField)
    // has given it up so we can respond to keyboard events
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        
        if let items = self.indexPathsForSelectedItems, items.count > 0 {
            for indexPath in self.indexPathsForSelectedItems! {
                self.deselectItem(at: indexPath, animated: true)
                self.delegate?.collectionView!(self, didDeselectItemAt: indexPath)
            }
        }
        
        self.removeFocusFromEntry()
        super.resignFirstResponder()
        return true
    }
    
    //
    //#pragma mark - Helper Methods
    //
    func addToSelectedContacts(model: ContactPickerModelProtocol, withCompletion completion: ContactPickerComplete?) {
        if self.indexPathsForVisibleItems.contains(self.entryCellIndexPath) {
            if let entryCell = self.cellForItem(at: self.entryCellIndexPath) as? ContactCollectionViewEntryCell {
                entryCell.reset()
            }
        } else {
            self.searchText = ContactPickerDefined.kDefaultEntryText
        }
        
        if !self.selectedContacts.contains(where: { (left) -> Bool in
            if left.contactTitle != model.contactTitle {
                return false
            }
            
            if left.contactSubtitle != model.contactSubtitle {
                return false
            }
            
            if left.contactImage != model.contactImage {
                return false
            }
            return true
        }) {
            self.selectedContacts.append(model)
            let originalOffset = self.contentOffset
            self.performBatchUpdates({
                let indexPath = IndexPath(row: self.selectedContacts.count - (self.showPrompt ? 0 : 1), section: 0)
                self.insertItems(at: [indexPath])
                self.contentOffset = originalOffset
            }) { (finished) in
                if finished {
                    completion?()
                }
                self.contactDelegate?.collectionView(at: self, didAdd: model)
            }
        }
    }
    
    func removeFromSelectedContacts(index: Int, withCompletion completion: ContactPickerComplete?) {
        let count = self.indexPathsForSelectedItems?.count ?? 0
        if self.selectedContacts.count + 1 > count {
            let model = self.selectedContacts[index]
            self.performBatchUpdates({
                self.selectedContacts.remove(at: index)
                if let indexPathOfSelectedCell = self.indexPathOfSelectedCell {
                    self.deselectItem(at: indexPathOfSelectedCell, animated: false)
                }
                self.deleteItems(at: [IndexPath(row: index + (self.showPrompt ? 1 : 0), section: 0)])
                self.scrollToItem(at: self.entryCellIndexPath, at: UICollectionView.ScrollPosition(rawValue: 0), animated: true)
            }) { (finished) in
                
                completion?()
                self.contactDelegate?.collectionView(at: self, didRemove: model)
                self.setFocusOnEntry()
            }
        }
    }
    
    func isCell(entry index: IndexPath) -> Bool {
        return index.row == self.entryCellIndex
    }
    
    func isCell(prompt index: IndexPath) -> Bool {
        return self.showPrompt && index.row == 0
    }
    
    func isCell(contact index: IndexPath) -> Bool {
        return !self.isCell(prompt: index) && !self.isCell(entry: index)
    }
    
    var entryCellIndex : Int {
        get {
            return self.selectedContacts.count + (self.showPrompt ? 1 : 0)
        }
    }
    
    func selectedContactIndexFromIndexPath(indexPath: IndexPath) -> Int {
        return self.selectedContactIndexFromRow(row: indexPath.row)
    }
    
    func selectedContactIndexFromRow(row: Int) -> Int {
        return row - (self.showPrompt ? 1 : 0)
    }
    
    var indexPathOfSelectedCell: IndexPath? {
        get {
            let count = self.indexPathsForSelectedItems?.count ?? 0
            if count > 0  {
                return self.indexPathsForSelectedItems?[0]
            } else {
                return nil
            }
        }
    }
    //
    func setFocusOnEntry() {
        if self.entryIsVisible {
            if let entryCell = self.cellForItem(at: self.entryCellIndexPath) as? ContactCollectionViewEntryCell {
                entryCell.setFocus()
            }
        } else {
            self.scrollToEntryAnimated(animated: true) {
                if let entryCell = self.cellForItem(at: self.entryCellIndexPath) as?  ContactCollectionViewEntryCell {
                    entryCell.setFocus()
                }
            }
        }
    }
    
    func removeFocusFromEntry() {
        if let entryCell = self.cellForItem(at: self.entryCellIndexPath) as? ContactCollectionViewEntryCell {
            entryCell.removeFocus()
        }
    }
    
    var entryIsVisible : Bool {
        return self.indexPathsForVisibleItems.contains(self.entryCellIndexPath)
    }
    
    func scrollToEntryAnimated(animated : Bool, onComplete complete : ContactPickerComplete?) {
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.contentOffset = CGPoint(x: 0, y: self.contentSize.height - self.bounds.size.height)
            }) { (finished) in
                complete?()
            }
        }
        else if self.showPrompt {
            //Check if there's any cell exists on that indexPath
            if let _ = self.dataSource?.collectionView(self, cellForItemAt: self.entryCellIndexPath) {
                self.scrollToItem(at: self.entryCellIndexPath, at: .bottom, animated: false)
            }
        }
    }
    
    
    //
    //#pragma mark - UICollectionViewDataSource
    //
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedContacts.count + (self.showPrompt ? 1 : 0) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.isCell(prompt: indexPath) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContactPromptCell", for: indexPath) as! ContactCollectionViewPromptCell
            cell.prompt = self._prompt
            self.promptCell = cell
            return cell
        } else if self.isCell(entry: indexPath) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContactEntryCell", for: indexPath) as! ContactCollectionViewEntryCell
            cell.delegate = self
            if self.isFirstResponder && self.indexPathOfSelectedCell == nil {
                cell.setFocus()
            }
            cell.text = self.searchText
            cell.enabled = self.allowsTextInput
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContactCell", for: indexPath) as! ContactCollectionViewContactCell
            cell.delegate = self.contactDelegate
            cell.model = self.selectedContacts[self.selectedContactIndexFromIndexPath(indexPath: indexPath)]
            if  self.indexPathOfSelectedCell == indexPath {
                cell.pickerFocused = true
            } else {
                cell.pickerFocused = false
            }
            return cell
        }
    }
    
    
    //- (UITextRange*) selectedTextRange
    //{
    //      // prevents crash when hitting delete on real keyboard
    //      return nil
    //}
    //
    //- (id<UITextInputDelegate>) inputDelegate
    //{
    //      // prevents crash when hitting delete on real keyboard
    //      return nil
    //}
}

//
//#pragma mark - UICollectionViewDelegateFlowLayout
//
extension ContactCollectionView : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var widthForItem: CGFloat = 0.0
        
        if self.isCell(prompt: indexPath) {
            widthForItem = ContactCollectionViewPromptCell.widthWithPrompt(prompt: self._prompt)
            widthForItem = max(30, widthForItem)
        } else if self.isCell(entry: indexPath) {
            let prototype = ContactCollectionViewEntryCell()
            widthForItem = max(50, prototype.widthForText(text: self.searchText))
        } else {
            if let cell = self.cellForItem(at: indexPath) as? ContactCollectionViewContactCell {
                widthForItem = cell.widthForCell()
            } else {
                let model = self.selectedContacts[self.selectedContactIndexFromIndexPath(indexPath: indexPath)]
                widthForItem = self.prototypeCell.widthForCellWithContact(model: model)
            }
        }
        return CGSize(width: min(self.maxContentWidth, widthForItem), height: CGFloat(self.cellHeight))
    }
}

//
//#pragma mark - UIKeyInput
//
extension ContactCollectionView : UIKeyInput {
    
    var hasText: Bool {
        return true
    }
    
    func insertText(_ text: String) {
        
    }
    
    func deleteBackward() {
        let count = self.indexPathsForSelectedItems?.count ?? 0
        if count > 0, let row = self.indexPathOfSelectedCell?.row {
            self.removeFromSelectedContacts(index: self.selectedContactIndexFromRow(row: row), withCompletion: nil)
        }
    }
}


//
//#pragma mark - ContactCollectionViewDelegateFlowLayout
//
extension ContactCollectionView : ContactCollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView?, willChangeContentSizeTo newSize: CGSize) {
        self.contactDelegate?.collectionView(at: self, willChangeContentSizeTo: newSize)
    }
}


//
//#pragma mark - UICollectionViewDelegate
//
extension ContactCollectionView : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ContactCollectionViewContactCell {
            self.becomeFirstResponder()
            
            if cell.pickerFocused == false {
                cell.pickerFocused = true
            } else {
                let callback = {
                    (selectedEmailAddresses: [DraftEmailData]) -> Void in
                    
                    if let contactGroup = cell.model as? ContactGroupVO { // must be contactGroupVO
                        if selectedEmailAddresses.count > 0 {
                            // update cell members
                            contactGroup.overwriteSelectedEmails(with: selectedEmailAddresses)
                            cell.prepareTitleForContactGroup()
                        } else {
                            // No member, delete this cell
                            self.removeFromSelectedContacts(index: self.selectedContactIndexFromRow(row: indexPath.row),
                                                            withCompletion: nil)
                        }
                    } else {
                        // TODO: handle error
                        PMLog.D("FatalError: This shouldn't happen")
                    }
                }
                
                self.contactDelegate?.collectionView(at: self, didSelect: cell.model, callback: callback)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return self.isCell(contact: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ContactCollectionViewContactCell {
            cell.pickerFocused = false
        }
    }
}


//
//#pragma mark - UITextFieldDelegateImproved
//
extension ContactCollectionView : UITextFieldDelegateImproved {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text ?? ""
        
        if string == "," || string == ";" {
            textField.resignFirstResponder()
            return false
        }
        
        let newString = text.replacingCharacters(in: Range(range, in: text)!, with: string)
        // If backspace is pressed and there isn't any text in the field, we want to select the
        // last selected contact and not let them delete the space we inserted (the space allows
        // us to catch the last backspace press - without it, we get no event!)
        if newString == "" && string == "" &&
            range.location == 0 &&
            range.length == 1 {
            if self.selectedContacts.count > 0 {
                textField.resignFirstResponder()
                
                let newSelectedIndexPath = IndexPath(row: self.selectedContacts.count - (self.showPrompt ? 0 : 1), section: 0)
                self.selectItem(at: newSelectedIndexPath, animated: true, scrollPosition: .bottom)
                self.delegate?.collectionView?(self, didSelectItemAt: newSelectedIndexPath)
                self.becomeFirstResponder()
            }
            return false
        }
        return true
    }
    
    func textFieldDidChange(textField: UITextField) {
        self.searchText = textField.text
        let left = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !left.isEmpty,
            (left.contains(check: ";") || left.contains(check: ",")) {
            self.contactDelegate?.collectionView(at: self, pasted: self.searchText, needFocus: true)
            return
        }
        self.contactDelegate?.collectionView(at: self, entryTextDidChange: textField.text ?? "")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let trimmedString = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
        if trimmedString.count > 0 {
            self.contactDelegate?.collectionView(at: self, didEnterCustom: trimmedString, needFocus: true)
        }
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let trimmedString = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
        if trimmedString.count > 0 {
            self.contactDelegate?.collectionView(at: self, didEnterCustom: trimmedString, needFocus: false)
        }
    }
}
