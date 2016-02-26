//
//  HtmlEditorViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/21/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit


class ComposeEmailViewController: ZSSRichTextEditor {
    
    
    // view model
    var viewModel : ComposeViewModel!
    
    // private views
    private var webView : UIWebView!
    private var composeView : ComposeView!
    
    // private vars
    private var timer : NSTimer!
    private var draggin : Bool! = false
    private var contacts: [ContactVO]! = [ContactVO]()
    private var actualEncryptionStep = EncryptionStep.DefinePassword
    private var encryptionPassword: String = ""
    private var encryptionConfirmPassword: String = ""
    private var encryptionPasswordHint: String = ""
    private var hasAccessToAddressBook: Bool = false
    
    private var attachments: [AnyObject]?
    
    @IBOutlet weak var expirationPicker: UIPickerView!
    // offsets
    private var composeViewSize : CGFloat = 186;
    
    // MARK : const values
    private let kNumberOfColumnsInTimePicker: Int = 2
    private let kNumberOfDaysInTimePicker: Int = 30
    private let kNumberOfHoursInTimePicker: Int = 24
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        setNeedsStatusBarAppearanceUpdate()
        
        self.baseURL = NSURL( fileURLWithPath: "https://protonmail.ch")
        //self.formatHTML = false
        self.webView = self.getWebView()
        
        // init views
        self.composeView = ComposeView(nibName: "ComposeView", bundle: nil)
        let w = UIScreen.mainScreen().applicationFrame.width;
        self.composeView.view.frame = CGRect(x: 0, y: 0, width: w, height: composeViewSize + 60)
        self.composeView.delegate = self
        self.composeView.datasource = self
        self.webView.scrollView.addSubview(composeView.view);
        self.webView.scrollView.bringSubviewToFront(composeView.view)
        
        // update content values
        updateMessageView()
        self.contacts = sharedContactDataService.allContactVOs()
        retrieveAllContacts()
        
        self.expirationPicker.alpha = 0.0
        self.expirationPicker.dataSource = self
        self.expirationPicker.delegate = self
        
        self.attachments = viewModel.getAttachments();
        
        // update header layous
        updateContentLayout(false)
        
        //change message as read
        self.viewModel.markAsRead();
    }
    
    internal func retrieveAllContacts() {
        sharedContactDataService.getContactVOs { (contacts, error) -> Void in
            if let error = error {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
            self.contacts = contacts
            
            self.composeView.toContactPicker.reloadData()
            self.composeView.ccContactPicker.reloadData()
            self.composeView.bccContactPicker.reloadData()
            
            self.composeView.toContactPicker.contactCollectionView.layoutIfNeeded()
            self.composeView.bccContactPicker.contactCollectionView.layoutIfNeeded()
            self.composeView.ccContactPicker.contactCollectionView.layoutIfNeeded()
            
            switch self.viewModel.messageAction!
            {
            case .OpenDraft, .Reply, .ReplyAll:
                self.focusTextEditor();
                self.composeView.notifyViewSize(true)
                break
            default:
                self.composeView.toContactPicker.becomeFirstResponder()
                break
            }
            
        }
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        self.composeView.notifyViewSize(true)
    }
    
    private func dismissKeyboard() {
        self.composeView.toContactPicker.becomeFirstResponder()
        self.composeView.toContactPicker.resignFirstResponder()
    }
    
    private func updateMessageView() {
        self.composeView.updateFromValue(self.viewModel.getDefaultAddress()?.email ?? "", pickerEnabled: true)
        self.composeView.subject.text = self.viewModel.getSubject();
        self.setHTML(self.viewModel.getHtmlBody())
    }
    
    override func viewWillAppear(animated: Bool) {
        self.updateAttachmentButton()
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarHit:", name: NotificationDefined.TouchStatusBar, object:nil)
        setupAutoSave()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationDefined.TouchStatusBar, object:nil)
        
        stopAutoSave()
    }
    
    internal func statusBarHit (notify: NSNotification) {
        webView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func configureNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: navigationBarTitleFont
        ]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func editorDidScrollWithPosition(position: Int) {
        super.editorDidScrollWithPosition(position)
        
        //let new_position = self.getCaretPosition().toInt() ?? 0
        //self.delegate?.editorSizeChanged(self.getContentSize())
        //self.delegate?.editorCaretPosition(new_position)
    }
    
    private func updateContentLayout(animation: Bool) {
        UIView.animateWithDuration(animation ? 0.25 : 0, animations: { () -> Void in
            for subview in self.webView.scrollView.subviews {
                let sub = subview as! UIView
                if sub == self.composeView.view {
                    continue
                } else if sub is UIImageView {
                    continue
                } else {
                    let h : CGFloat = self.composeViewSize
                    sub.frame = CGRect(x: sub.frame.origin.x, y: h, width: sub.frame.width, height: sub.frame.height);
                }
            }
        })
    }
    
    
    @IBAction func send_clicked(sender: AnyObject) {
        self.dismissKeyboard()
        
        if self.composeView.expirationTimeInterval > 0 {
            if self.composeView.hasOutSideEmails && count(self.encryptionPassword) <= 0 {
                self.composeView.showPasswordAndConfirmDoesntMatch(self.composeView.kExpirationNeedsPWDError)
                return;
            }
        }
        
        if self.viewModel.toSelectedContacts.count <= 0 && self.viewModel.ccSelectedContacts.count <= 0 && self.viewModel.bccSelectedContacts.count <= 0 {
            let alert = UIAlertController(title: NSLocalizedString("Alert"), message: NSLocalizedString("You need at least one recipient to send"), preferredStyle: .Alert)
            alert.addAction((UIAlertAction.okAction()))
            presentViewController(alert, animated: true, completion: nil)
            return;
        }
        
        stopAutoSave()
        self.collectDraft()
        self.viewModel.sendMessage()
        // show message
        NSError.alertMessageSendingToast();
        if presentingViewController != nil {
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            navigationController?.popToRootViewControllerAnimated(true)
        }
        
    }
    
    @IBAction func cancel_clicked(sender: UIBarButtonItem) {
        
        self.dismissKeyboard()
        let dismiss: (() -> Void) = {
            if self.presentingViewController != nil {
                self.dismissViewControllerAnimated(true, completion: nil)
            } else {
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
        
        if self.viewModel.hasDraft || composeView.hasContent || ((attachments?.count ?? 0) > 0) {
            let alertController = UIAlertController(title: NSLocalizedString("Confirmation"), message: nil, preferredStyle: .ActionSheet)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Save draft"), style: .Default, handler: { (action) -> Void in
                self.stopAutoSave()
                self.collectDraft()
                self.viewModel.updateDraft()
                dismiss()
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Discard draft"), style: .Destructive, handler: { (action) -> Void in
                self.stopAutoSave()
                self.viewModel.deleteDraft()
                dismiss()
            }))
            
            alertController.popoverPresentationController?.barButtonItem = sender
            alertController.popoverPresentationController?.sourceRect = self.view.frame
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            dismiss()
        }
    }
    
    // MARK: - Private methods
    private func setupAutoSave()
    {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(120, target: self, selector: "autoSaveTimer", userInfo: nil, repeats: true)
        if viewModel.getActionType() != .OpenDraft {
            self.timer.fire()
        }
    }
    
    private func stopAutoSave()
    {
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
    }
    
    func autoSaveTimer()
    {
        self.collectDraft()
        self.viewModel.updateDraft()
    }
    
    private func collectDraft()
    {
        self.viewModel.collectDraft(
            self.composeView.subject.text,
            body: self.getHTML(),
            expir: self.composeView.expirationTimeInterval,
            pwd:self.encryptionPassword,
            pwdHit:self.encryptionPasswordHint
        )
    }
    
    private func updateAttachmentButton () {
        if attachments?.count > 0 {
            self.composeView.updateAttachmentButton(true)
        } else {
            self.composeView.updateAttachmentButton(false)
        }
    }
}

// MARK : - view extensions
extension ComposeEmailViewController : ComposeViewDelegate {
    func composeViewPickFrom(composeView: ComposeView) {
        if attachments?.count > 0 {
            let alertController = "Please remove all attachments before changing sender!".alertController()
            alertController.addOKAction()
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: NSLocalizedString("Change sender address to .."), message: nil, preferredStyle: .ActionSheet)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
            let multi_domains = self.viewModel.getAddresses()
            let defaultAddr = self.viewModel.getDefaultAddress()
            for (var addr) in multi_domains {
                if addr.status == 1 && addr.receive == 1 && defaultAddr != addr {
                    alertController.addAction(UIAlertAction(title: addr.email, style: .Default, handler: { (action) -> Void in
                        self.viewModel.updateAddressID(addr.address_id)
                        self.composeView.updateFromValue(addr.email, pickerEnabled: true)
                    }))
                }
            }
            alertController.popoverPresentationController?.sourceView = self.composeView.fromView
            alertController.popoverPresentationController?.sourceRect = self.composeView.fromView.frame
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func ComposeViewDidSizeChanged(size: CGSize) {
        //self.composeSize = size
        //self.updateViewSize()
        self.composeViewSize = size.height;
        let w = UIScreen.mainScreen().applicationFrame.width;
        self.composeView.view.frame = CGRect(x: 0, y: 0, width: w, height: composeViewSize )
        
        self.updateContentLayout(true)
    }
    
    func ComposeViewDidOffsetChanged(offset: CGPoint){
        //        if ( self.cousorOffset  != offset.y)
        //        {
        //            self.cousorOffset = offset.y
        //            self.updateAutoScroll()
        //        }
    }
    
    func composeViewDidTapNextButton(composeView: ComposeView) {
        switch(actualEncryptionStep) {
        case EncryptionStep.DefinePassword:
            self.encryptionPassword = composeView.encryptedPasswordTextField.text ?? ""
            if !self.encryptionPassword.isEmpty {
                self.actualEncryptionStep = EncryptionStep.ConfirmPassword
                self.composeView.showConfirmPasswordView()
            } else {
                self.composeView.showPasswordAndConfirmDoesntMatch(self.composeView.kEmptyEOPWD);
            }
        case EncryptionStep.ConfirmPassword:
            self.encryptionConfirmPassword = composeView.encryptedPasswordTextField.text ?? ""
            
            if (self.encryptionPassword == self.encryptionConfirmPassword) {
                self.actualEncryptionStep = EncryptionStep.DefineHintPassword
                self.composeView.hidePasswordAndConfirmDoesntMatch()
                self.composeView.showPasswordHintView()
            } else {
                self.composeView.showPasswordAndConfirmDoesntMatch(self.composeView.kConfirmError)
            }
            
        case EncryptionStep.DefineHintPassword:
            self.encryptionPasswordHint = composeView.encryptedPasswordTextField.text ?? ""
            self.actualEncryptionStep = EncryptionStep.DefinePassword
            self.composeView.showEncryptionDone()
        default:
            PMLog.D("No step defined.")
        }
    }
    
    func composeViewDidTapEncryptedButton(composeView: ComposeView) {
        self.actualEncryptionStep = EncryptionStep.DefinePassword
        self.composeView.showDefinePasswordView()
        self.composeView.hidePasswordAndConfirmDoesntMatch()
    }
    
    func composeViewDidTapAttachmentButton(composeView: ComposeView) {
        if let viewController = UIStoryboard.instantiateInitialViewController(storyboard: .attachments) as? UINavigationController {
            if let attachmentsViewController = viewController.viewControllers.first as? AttachmentsTableViewController {
                attachmentsViewController.delegate = self
                attachmentsViewController.message = viewModel.message;
                if let attachments = attachments {
                    attachmentsViewController.attachments = viewModel.getAttachments() ?? []
                }
            }
            presentViewController(viewController, animated: true, completion: nil)
        }
    }
    
    func composeViewDidTapExpirationButton(composeView: ComposeView)
    {
        self.expirationPicker.alpha = 1;
        self.view.bringSubviewToFront(expirationPicker)
    }
    
    func composeViewHideExpirationView(composeView: ComposeView)
    {
        self.expirationPicker.alpha = 0;
    }
    
    func composeViewCancelExpirationData(composeView: ComposeView)
    {
        self.expirationPicker.selectRow(0, inComponent: 0, animated: true)
        self.expirationPicker.selectRow(0, inComponent: 1, animated: true)
    }
    
    func composeViewCollectExpirationData(composeView: ComposeView)
    {
        let selectedDay = expirationPicker.selectedRowInComponent(0)
        let selectedHour = expirationPicker.selectedRowInComponent(1)
        if self.composeView.setExpirationValue(selectedDay, hour: selectedHour)
        {
            self.expirationPicker.alpha = 0;
        }
    }
    
    func composeView(composeView: ComposeView, didAddContact contact: ContactVO, toPicker picker: MBContactPicker)
    {
        if (picker == composeView.toContactPicker) {
            self.viewModel.toSelectedContacts.append(contact)
        } else if (picker == composeView.ccContactPicker) {
            self.viewModel.ccSelectedContacts.append(contact)
        } else if (picker == composeView.bccContactPicker) {
            self.viewModel.bccSelectedContacts.append(contact)
        }
    }
    
    func composeView(composeView: ComposeView, didRemoveContact contact: ContactVO, fromPicker picker: MBContactPicker)
    {// here each logic most same, need refactor later
        if (picker == composeView.toContactPicker) {
            var contactIndex = -1
            let selectedContacts = self.viewModel.toSelectedContacts
            for (index, selectedContact) in enumerate(selectedContacts) {
                if (contact.email == selectedContact.email) {
                    contactIndex = index
                }
            }
            if (contactIndex >= 0) {
                self.viewModel.toSelectedContacts.removeAtIndex(contactIndex)
            }
        } else if (picker == composeView.ccContactPicker) {
            var contactIndex = -1
            let selectedContacts = self.viewModel.ccSelectedContacts
            for (index, selectedContact) in enumerate(selectedContacts) {
                if (contact.email == selectedContact.email) {
                    contactIndex = index
                }
            }
            if (contactIndex >= 0) {
                self.viewModel.ccSelectedContacts.removeAtIndex(contactIndex)
            }
        } else if (picker == composeView.bccContactPicker) {
            var contactIndex = -1
            let selectedContacts = self.viewModel.bccSelectedContacts
            for (index, selectedContact) in enumerate(selectedContacts) {
                if (contact.email == selectedContact.email) {
                    contactIndex = index
                }
            }
            if (contactIndex >= 0) {
                self.viewModel.bccSelectedContacts.removeAtIndex(contactIndex)
            }
        }
    }
}


// MARK : compose data source
extension ComposeEmailViewController : ComposeViewDataSource {
    func composeViewContactsModelForPicker(composeView: ComposeView, picker: MBContactPicker) -> [AnyObject]! {
        return contacts
    }
    
    func composeViewSelectedContactsForPicker(composeView: ComposeView, picker: MBContactPicker) ->  [AnyObject]! {
        var selectedContacts: [ContactVO] = [ContactVO]()
        if (picker == composeView.toContactPicker) {
            selectedContacts = self.viewModel.toSelectedContacts
        } else if (picker == composeView.ccContactPicker) {
            selectedContacts = self.viewModel.ccSelectedContacts
        } else if (picker == composeView.bccContactPicker) {
            selectedContacts = self.viewModel.bccSelectedContacts
        }
        return selectedContacts
    }
}


// MARK: - AttachmentsViewControllerDelegate
extension ComposeEmailViewController: AttachmentsTableViewControllerDelegate {
    
    func attachments(attViewController: AttachmentsTableViewController, didFinishPickingAttachments attachments: [AnyObject]) {
        self.attachments = attachments
    }
    
    func attachments(attViewController: AttachmentsTableViewController, didPickedAttachment attachment: Attachment) {
        self.collectDraft()
        self.viewModel.uploadAtt(attachment)
    }
    
    func attachments(attViewController: AttachmentsTableViewController, didDeletedAttachment attachment: Attachment) {
        self.collectDraft()
        self.viewModel.deleteAtt(attachment)
    }
}

// MARK: - UIPickerViewDataSource

extension ComposeEmailViewController: UIPickerViewDataSource {
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

extension ComposeEmailViewController: UIPickerViewDelegate {
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


