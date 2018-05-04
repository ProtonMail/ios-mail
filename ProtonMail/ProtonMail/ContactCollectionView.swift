//
//  ContactCollectionView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/27/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

//Complete
typealias ContactPickerComplete = (() -> Void)

@objc protocol ContactCollectionViewDelegate : NSObjectProtocol {
    
    @objc optional func contactCollectionView (contactCollectionView: UICollectionView?, willChangeContentSizeTo newSize: CGSize)
    @objc optional func contactCollectionView (contactCollectionView: ContactCollectionView, entryTextDidChange text: String)
    @objc optional func contactCollectionView (contactCollectionView: ContactCollectionView, didEnterCustomContact text: String, needFocus focus: Bool)
    @objc optional func contactCollectionView (contactCollectionView: ContactCollectionView, didSelectContact model: ContactPickerModelProtocol)
    @objc optional func contactCollectionView (contactCollectionView: ContactCollectionView, didAddContact model: ContactPickerModelProtocol)
    @objc optional func contactCollectionView (contactCollectionView: ContactCollectionView, didRemoveContact model: ContactPickerModelProtocol)
    @objc optional func contactCollectionView (contactCollectionView: ContactCollectionView, didEnterCustomText text: String)
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
    
    var contactDelegate: ContactCollectionViewDelegate?
    
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
        
        let layout = self.collectionViewLayout as! ContactCollectionViewFlowLayout
        layout.minimumInteritemSpacing = 0 //5
        layout.minimumLineSpacing = 0 // 1
        layout.sectionInset = UIEdgeInsetsMake(0, 6, 0, 6)

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
        self.forceRelayout()
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
            if self.indexPathsForVisibleItems.contains(self.entryCellIndexPath) {//&& self.entryCellIndexPath
                self.reloadItems(at: [self.entryCellIndexPath])
            }
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
            if self._showPrompt == newValue {
                return
            }
            
            _showPrompt = newValue
            
            // If there aren't any visible cells, then one of the following is true:
            //
            // 1)   -[UICollectionView reloadData] hasn't yet been called.  In that case, calling `insertItemsAtIndexPaths:` or
            //      `deleteItemsAtIndexPaths:` could cause undesired behavior.
            // 2)   There really aren't any cells.  This shouldn't happen since, at a minimum, the entry cell should be present.
            if self.visibleCells.count == 0 {
                return
            }
            
            if self._showPrompt {
                self.insertItems(at: [IndexPath(row: 0, section: 0)])
            } else {
                self.deleteItems(at: [IndexPath(row: 0, section: 0)])
            }
        }
    }
    
    var prompt : String {
        get {
            return _prompt
        }
        set {
            self._prompt = newValue
            // If there aren't any visible cells, then one of the following is true:
            //
            // 1)   -[UICollectionView reloadData] hasn't yet been called.  In that case, calling `reloadItemsAtIndexPaths:` could cause undesired behavior.
            // 2)   There really aren't any cells.  This shouldn't happen since, at a minimum, the entry cell should be present.
            if (self.showPrompt && self.visibleCells.count > 0)
            {
                self.reloadItems(at: [IndexPath(row: 0, section: 0)])
            }
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
                if let delegate = self.contactDelegate, delegate.responds(to: #selector(ContactCollectionViewDelegate.contactCollectionView(contactCollectionView:didAddContact:))) {
                    delegate.contactCollectionView!(contactCollectionView: self, didAddContact: model)
                }
            }
        }
    }
    
    func removeFromSelectedContacts(index: Int, withCompletion completion: ContactPickerComplete?) {
        if self.selectedContacts.count + 1 > self.indexPathsForSelectedItems?.count {
            let model = self.selectedContacts[index]
            self.performBatchUpdates({
                self.selectedContacts.remove(at: index)
                self.deselectItem(at: self.indexPathOfSelectedCell!, animated: false)
                self.deleteItems(at: [IndexPath(row: index + (self.showPrompt ? 1 : 0), section: 0)])
                self.scrollToItem(at: self.entryCellIndexPath, at: UICollectionViewScrollPosition(rawValue: 0), animated: true)
            }) { (finished) in
                
                completion?()
                if let delegate = self.contactDelegate, delegate.responds(to: #selector(ContactCollectionViewDelegate.contactCollectionView(contactCollectionView:didRemoveContact:))) {
                    delegate.contactCollectionView!(contactCollectionView: self, didRemoveContact: model)
                }
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
            if self.indexPathsForSelectedItems?.count > 0  {
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
            self.scrollToItem(at: self.entryCellIndexPath, at: .bottom, animated: false)
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
            widthForItem += 30
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
        if self.indexPathsForSelectedItems?.count > 0, let row = self.indexPathOfSelectedCell?.row {
            self.removeFromSelectedContacts(index: self.selectedContactIndexFromRow(row: row), withCompletion: nil)
        }
    }
}


//
//#pragma mark - ContactCollectionViewDelegateFlowLayout
//
extension ContactCollectionView : ContactCollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView?, willChangeContentSizeTo newSize: CGSize) {
        if let delegate = self.contactDelegate, delegate.responds(to: #selector(ContactCollectionViewDelegate.contactCollectionView(contactCollectionView:willChangeContentSizeTo:))) {
            delegate.contactCollectionView!(contactCollectionView: self, willChangeContentSizeTo: newSize)
        }
    }
}


//
//#pragma mark - UICollectionViewDelegate
//
extension ContactCollectionView : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ContactCollectionViewContactCell {
            self.becomeFirstResponder()
            cell.pickerFocused = true
            if let delegate = self.contactDelegate, delegate.responds(to: #selector(ContactCollectionViewDelegate.contactCollectionView(contactCollectionView:didSelectContact:))) {
                delegate.contactCollectionView!(contactCollectionView: self, didSelectContact: cell.model)
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
        if let delegate = self.contactDelegate, delegate.responds(to: #selector(ContactCollectionViewDelegate.contactCollectionView(contactCollectionView:entryTextDidChange:))) {
            delegate.contactCollectionView!(contactCollectionView: self, entryTextDidChange: textField.text ?? "")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if let delegate = self.contactDelegate, delegate.responds(to: #selector(ContactCollectionViewDelegate.contactCollectionView(contactCollectionView:didEnterCustomContact:needFocus:))) {
            
            //NSString *trimmedString = [textField.text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]
            let trimmedString = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
            if trimmedString.count > 0 {
                delegate.contactCollectionView!(contactCollectionView: self, didEnterCustomContact: trimmedString, needFocus: true)
            }
        }
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let delegate = self.contactDelegate, delegate.responds(to: #selector(ContactCollectionViewDelegate.contactCollectionView(contactCollectionView:didEnterCustomContact:needFocus:))) {
            
            //NSString *trimmedString = [textField.text stringByTrimmingCharactersInSet:
            let trimmedString = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
            if trimmedString.count > 0 {
                delegate.contactCollectionView!(contactCollectionView: self, didEnterCustomContact: trimmedString, needFocus: false)
            }
        }
    }
}
