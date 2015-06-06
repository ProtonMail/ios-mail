//
//  ComposeViewControllerN.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class ComposeViewController : ProtonMailViewController {
    
    private struct EncryptionStep {
        static let DefinePassword = "DefinePassword"
        static let ConfirmPassword = "ConfirmPassword"
        static let DefineHintPassword = "DefineHintPassword"
    }

    let draftAction = "draft"
    
    // MARK : - Views
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var expirationPicker: UIPickerView!
    
    private var draggin : Bool! = false
    
    private var composeView : ComposeViewN!
    
    // MARK : const values
    private let kNumberOfColumnsInTimePicker: Int = 2
    private let kNumberOfDaysInTimePicker: Int = 30
    private let kNumberOfHoursInTimePicker: Int = 24
    
    
    // MARK : - Private attributes
    private var composeSize : CGSize!
    
    var attachments: [AnyObject]?
    var message: Message?
    var action: String?
    
    var toSelectedContacts: [ContactVO]! = [ContactVO]()
    private var ccSelectedContacts: [ContactVO]! = [ContactVO]()
    private var bccSelectedContacts: [ContactVO]! = [ContactVO]()
    private var contacts: [ContactVO]! = [ContactVO]()
    private var actualEncryptionStep = EncryptionStep.DefinePassword
    private var encryptionPassword: String = ""
    private var encryptionConfirmPassword: String = ""
    private var encryptionPasswordHint: String = ""
    private var hasAccessToAddressBook: Bool = false
    
    // MARK : - Data provider
    private var fetchedResultsController: NSFetchedResultsController?
    
    // MARK : - overrid view functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.composeSize  = CGSize.zeroSize
        
        self.expirationPicker.alpha = 0.0
        self.expirationPicker.dataSource = self
        self.expirationPicker.delegate = self
        
        self.composeView = ComposeViewN(nibName: "ComposeViewN", bundle: nil)
        self.composeView.delegate = self
        self.composeView.datasource = self
        
        self.scrollView.addSubview(composeView.view);
        self.composeView.view.frame = scrollView.frame
        
        self.scrollView.delegate = self
        self.handleMessage(message, action: action)
        
        self.contacts = sharedContactDataService.allContactVOs()
        self.composeView.toContactPicker.reloadData()
        self.composeView.ccContactPicker.reloadData()
        self.composeView.bccContactPicker.reloadData()
        self.composeView.toContactPicker.becomeFirstResponder()
        
        if message != nil {
            message?.isRead = true;
            if let error = message!.managedObjectContext?.saveUpstreamIfNeeded() {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if ccSelectedContacts.count > 0 {
            composeView.plusButtonHandle()
            composeView.notifyViewSize(true)
        }
    }
    
    // MARK : - View actions
    @IBAction func cancelClicked(sender: AnyObject) {
        let dismiss: (() -> Void) = {
            if self.action == self.draftAction {
                self.navigationController?.popViewControllerAnimated(true)
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        
        if composeView.hasContent || ((attachments?.count ?? 0) > 0) {
            let alertController = UIAlertController(title: NSLocalizedString("Confirmation"), message: nil, preferredStyle: .ActionSheet)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Save draft"), style: .Default, handler: { (action) -> Void in
                sharedMessageDataService.saveDraft(
                    recipientList: self.composeView.toContacts,
                    bccList: self.composeView.bccContacts,
                    ccList: self.composeView.ccContacts,
                    title: self.composeView.subjectTitle,
                    encryptionPassword: self.encryptionPassword,
                    passwordHint: self.encryptionPasswordHint,
                    expirationTimeInterval: self.composeView.expirationTimeInterval,
                    body: self.composeView.htmlEditor.getHTML(),
                    attachments: self.attachments)
                
                dismiss()
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Discard draft"), style: .Destructive, handler: { (action) -> Void in
                dismiss()
            }))
            
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            dismiss()
        }
    }
    
    @IBAction func sendClicked(sender: AnyObject) {
        sharedMessageDataService.send(
            recipientList: self.composeView.toContacts,
            bccList: self.composeView.bccContacts,
            ccList: self.composeView.ccContacts,
            title: self.composeView.subjectTitle,
            encryptionPassword: self.encryptionPassword,
            passwordHint: self.encryptionPasswordHint,
            expirationTimeInterval: self.composeView.expirationTimeInterval,
            body: self.composeView.htmlEditor.getHTML(),
            attachments: self.attachments,
            completion: {_, _, error in
                if error == nil {
                    if let message = self.message {
                        println("MessageID after send:\(message.messageID)")
                        println("Message Location : \(message.location )")
                        if(message.messageID != "0" && message.location == MessageLocation.draft)
                        {
                            message.location = .trash
                        }
                        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
                            NSLog("\(__FUNCTION__) error: \(error)")
                        }
                    }
                }
        })
        
        if presentingViewController != nil {
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
    
    // MARK: - Private methods
    private func updateViewSizeForKeyboard(offset : Int)
    {
        
    }
    
    private func updateViewSize()
    {
        self.scrollView.contentSize = CGSize(width: composeSize.width, height: composeSize.height)
    }

    private func handleMessage(message: Message?, action: String?) {
        let signature = !sharedUserDataService.signature.isEmpty ? "\n\n\(sharedUserDataService.signature)" : ""
        let htmlString = "<div><br></div><div><br></div><div><br></div><div><br></div><\(signature)";
        self.composeView.htmlEditor.setHTML(htmlString);
        
        if let message = message {
            if let action = action {
                if action == ComposeViewN.ComposeMessageAction.Reply || action == ComposeViewN.ComposeMessageAction.ReplyAll {
                    composeView.subject.text = "Re: \(message.title)"
                    toSelectedContacts.append(ContactVO(id: "", name: message.senderName, email: message.sender))
                    
                    let replyMessage = NSLocalizedString("Reply message")
                    let body = message.decryptBodyIfNeeded(nil) ?? ""
                    let time = message.time?.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? ""
                    let replyHeader = time + ", " + message.senderName + " <'\(message.sender)'>"
                    let sp = "<div>\(replyHeader) wrote:</div><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\"><tbody><tr><td align=\"center\" valign=\"top\"> <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"background-color:transparent;border-bottom:0;border-bottom:solid 1px #00929f\" width=\"600\"> "
                    
                    self.composeView.htmlEditor.setHTML("\(htmlString) \(sp) \(body)</blockquote>")
                    
                    if action == ComposeViewN.ComposeMessageAction.ReplyAll {
                        updateSelectedContacts(&ccSelectedContacts, withNameList: message.ccNameList, emailList: message.ccList)
                    }
                } else if action == ComposeViewN.ComposeMessageAction.Forward {
                    composeView.subject.text = "Fwd: \(message.title)"
                    
                    let time = message.time?.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? ""
                    
                    var forwardHeader = "<br><br><br>---------- Forwarded message ----------<br>From: \(message.senderName)<br>Date: \(time)<br>Subject: \(message.title)"
                    if message.recipientList != "" {
                        forwardHeader += "<br>To: \(message.recipientList)<br>"
                    }
                    if message.ccList != "" {
                        forwardHeader += "<br>To: \(message.ccList)<br>"
                    }
                    forwardHeader += "<br><br><br>"
                    
                    
                    let body = message.decryptBodyIfNeeded(nil) ?? ""
                    
                    self.composeView.htmlEditor.setHTML("<br><br><br>\(signature) \(forwardHeader) \(body)")
                    
                } else if action == draftAction {
                    navigationItem.leftBarButtonItem = nil
                    
                    updateSelectedContacts(&toSelectedContacts, withNameList: message.recipientNameList, emailList: message.recipientList)
                    updateSelectedContacts(&ccSelectedContacts, withNameList: message.ccNameList, emailList: message.ccList)
                    updateSelectedContacts(&bccSelectedContacts, withNameList: message.bccNameList, emailList: message.bccList)
                    
                    composeView.subject.text = message.title
                    
                    if !message.attachments.isEmpty {
                        attachments = []
                    }
                    
                    for attachment in message.attachments.allObjects as! [Attachment] {
                        if let fileData = attachment.fileData {
                            attachments?.append(fileData)
                        }
                    }
                    
                    var error: NSError?
                    self.composeView.htmlEditor.setHTML(message.decryptBodyIfNeeded(&error) ?? "")
                    if error != nil {
                        NSLog("\(__FUNCTION__) error: \(error)")
                    }
                }
            }
        }
    }
    
    private func updateSelectedContacts(inout selectedContacts: [ContactVO]!, withNameList nameList: String, emailList: String) {
        if selectedContacts == nil {
            selectedContacts = []
        }
        
        let emails = emailList.splitByComma()
        var names = nameList.splitByComma()
        
        // this prevents a crash if there are less names than emails
        if count(names) != count(emails) {
            names = emails
        }
        
        let nameCount = names.count
        let emailCount = count(emails)
        for var i = 0; i < emailCount; i++ {
            selectedContacts.append(ContactVO(id: "", name: ((i>=0 && i<nameCount) ? names[i] : ""), email: emails[i]))
        }
    }
}



// MARK : - view extensions
extension ComposeViewController : ComposeViewNDelegate {
    
    func ComposeViewNDidSizeChanged(size: CGSize) {
        self.composeSize = size
     
        self.updateViewSize()
    }
    
    func ComposeViewNDidOffsetChanged(offset: CGPoint){
        
        let currentOffsetY = self.scrollView.contentOffset.y;
        
        let h : CGFloat = 258;
        
        if !self.draggin {
            
            if ((offset.y + h - currentOffsetY) > self.scrollView.frame.height ) {
                self.scrollView.contentOffset = CGPoint(x: 0, y: self.scrollView.frame.height - currentOffsetY + 20)
            }
        }
    }
    
    func composeViewDidTapNextButton(composeView: ComposeViewN) {
        switch(actualEncryptionStep) {
        case EncryptionStep.DefinePassword:
            self.encryptionPassword = composeView.encryptedPasswordTextField.text ?? ""
            self.actualEncryptionStep = EncryptionStep.ConfirmPassword
            self.composeView.showConfirmPasswordView()
            
        case EncryptionStep.ConfirmPassword:
            self.encryptionConfirmPassword = composeView.encryptedPasswordTextField.text ?? ""
            
            if (self.encryptionPassword == self.encryptionConfirmPassword) {
                self.actualEncryptionStep = EncryptionStep.DefineHintPassword
                self.composeView.hidePasswordAndConfirmDoesntMatch()
                self.composeView.showPasswordHintView()
            } else {
                self.composeView.showPasswordAndConfirmDoesntMatch()
            }
            
        case EncryptionStep.DefineHintPassword:
            self.encryptionPasswordHint = composeView.encryptedPasswordTextField.text ?? ""
            self.actualEncryptionStep = EncryptionStep.DefinePassword
            self.composeView.showEncryptionDone()
        default:
            println("No step defined.")
        }
    }
    
    func composeViewDidTapEncryptedButton(composeView: ComposeViewN) {
         self.actualEncryptionStep = EncryptionStep.DefinePassword
         self.composeView.showDefinePasswordView()
         self.composeView.hidePasswordAndConfirmDoesntMatch()
    }
    
    func composeViewDidTapAttachmentButton(composeView: ComposeViewN) {
        if let viewController = UIStoryboard.instantiateInitialViewController(storyboard: .attachments) as? UINavigationController {
            if let attachmentsViewController = viewController.viewControllers.first as? AttachmentsViewController {
                attachmentsViewController.delegate = self
                
                if let attachments = attachments {
                    attachmentsViewController.attachments = attachments
                }
            }
            
            presentViewController(viewController, animated: true, completion: nil)
        }

    }
    
    func composeViewDidTapExpirationButton(composeView: ComposeViewN)
    {
        self.expirationPicker.alpha = 1;
    }
    
    func composeViewHideExpirationView(composeView: ComposeViewN)
    {
         self.expirationPicker.alpha = 0;
    }
    
    func composeViewCancelExpirationData(composeView: ComposeViewN)
    {
        self.expirationPicker.selectRow(0, inComponent: 0, animated: true)
        self.expirationPicker.selectRow(0, inComponent: 1, animated: true)
    }
    
    func composeViewCollectExpirationData(composeView: ComposeViewN)
    {
        let selectedDay = expirationPicker.selectedRowInComponent(0)
        let selectedHour = expirationPicker.selectedRowInComponent(1)
        if self.composeView.setExpirationValue(selectedDay, hour: selectedHour)
        {
            self.expirationPicker.alpha = 0;
        }
    }
    
    func composeView(composeView: ComposeViewN, didAddContact contact: ContactVO, toPicker picker: MBContactPicker)
    {
        var selectedContacts: [ContactVO] = [ContactVO]()
        
        if (picker == composeView.toContactPicker) {
            selectedContacts = toSelectedContacts
        } else if (picker == composeView.ccContactPicker) {
            selectedContacts = ccSelectedContacts
        } else if (picker == composeView.bccContactPicker) {
            selectedContacts = bccSelectedContacts
        }
        
        selectedContacts.append(contact)

    }
    func composeView(composeView: ComposeViewN, didRemoveContact contact: ContactVO, fromPicker picker: MBContactPicker)
    {
        var contactIndex = -1
        
        var selectedContacts: [ContactVO] = [ContactVO]()
        
        if (picker == composeView.toContactPicker) {
            selectedContacts = toSelectedContacts
        } else if (picker == composeView.ccContactPicker) {
            selectedContacts = ccSelectedContacts
        } else if (picker == composeView.bccContactPicker) {
            selectedContacts = bccSelectedContacts
        }
        
        for (index, selectedContact) in enumerate(selectedContacts) {
            if (contact.email == selectedContact.email) {
                contactIndex = index
            }
        }
        
        if (contactIndex >= 0) {
            selectedContacts.removeAtIndex(contactIndex)
        }
    }
}


extension ComposeViewController : ComposeViewNDataSource {
    func composeViewContactsModelForPicker(composeView: ComposeViewN, picker: MBContactPicker) -> [AnyObject]! {
        return contacts
    }
    
    func composeViewSelectedContactsForPicker(composeView: ComposeViewN, picker: MBContactPicker) ->  [AnyObject]! {
        
        var selectedContacts: [ContactVO] = [ContactVO]()
        
        if (picker == composeView.toContactPicker) {
            selectedContacts = toSelectedContacts
        } else if (picker == composeView.ccContactPicker) {
            selectedContacts = ccSelectedContacts
        } else if (picker == composeView.bccContactPicker) {
            selectedContacts = bccSelectedContacts
        }
        
        return selectedContacts
    }
    
}

// MARK: - AttachmentsViewControllerDelegate
extension ComposeViewController: AttachmentsViewControllerDelegate {
    func attachmentsViewController(attachmentsViewController: AttachmentsViewController, didFinishPickingAttachments attachments: [AnyObject]) {
        self.attachments = attachments
    }
}



// MARK: - UIPickerViewDataSource
extension ComposeViewController: UIPickerViewDataSource {
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return kNumberOfColumnsInTimePicker
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (component == 0) {
            return kNumberOfDaysInTimePicker
        } else {
            return kNumberOfHoursInTimePicker
        }
    }
}


// MARK: - UIPickerViewDelegate
extension ComposeViewController: UIPickerViewDelegate {
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if (component == 0) {
            return "\(row) days"
        } else {
            return "\(row) hours"
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedDay = pickerView.selectedRowInComponent(0)
        let selectedHour = pickerView.selectedRowInComponent(1)
        
        let day = "\(selectedDay) days"
        let hour = "\(selectedHour) hours"
        
        self.composeView.updateExpirationValue(((Double(selectedDay) * 24) + Double(selectedHour)) * 3600, text: "\(day) \(hour)")
    }
}


extension ComposeViewController : UIScrollViewDelegate {
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.draggin = true;
        println("drig")
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.draggin = false
    }
}

// MARK: - Message extension

extension String {
    private func splitByComma() -> [String] {
        return split(self) {$0 == ","}
    }
}

///

