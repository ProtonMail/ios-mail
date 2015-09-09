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
    private var userAddress : Array<Address>!
    
    private var attachments: [AnyObject]?
    
    @IBOutlet weak var expirationPicker: UIPickerView!
    // offsets
    private var composeViewSize : CGFloat = 138;
    
    // MARK : const values
    private let kNumberOfColumnsInTimePicker: Int = 2
    private let kNumberOfDaysInTimePicker: Int = 30
    private let kNumberOfHoursInTimePicker: Int = 24
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        setNeedsStatusBarAppearanceUpdate()
        
        self.baseURL = NSURL( fileURLWithPath: "https://protonmail.ch")
        self.webView = self.getWebView()
        
        // init views
        self.composeView = ComposeView(nibName: "ComposeView", bundle: nil)
        let w = UIScreen.mainScreen().applicationFrame.width;
        self.composeView.view.frame = CGRect(x: 0, y: 0, width: w, height: composeViewSize + 60)
        self.composeView.delegate = self
        self.composeView.datasource = self
        self.webView.scrollView.addSubview(composeView.view);
        self.webView.scrollView.bringSubviewToFront(composeView.view)
        
        // get user's address
        userAddress = sharedUserDataService.userAddresses
        
        // update content values
        updateMessageView()
        self.contacts = sharedContactDataService.allContactVOs()
        self.composeView.toContactPicker.reloadData()
        self.composeView.ccContactPicker.reloadData()
        self.composeView.bccContactPicker.reloadData()
        
        self.expirationPicker.alpha = 0.0
        self.expirationPicker.dataSource = self
        self.expirationPicker.delegate = self
        
        // update header layous
        updateContentLayout(false)
        
        //change message as read
        self.viewModel.markAsRead();
    }
    
    private func updateMessageView() {
        self.composeView.subject.text = self.viewModel.getSubject();
        self.setHTML(self.viewModel.getHtmlBody())
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarHit:", name: "touchStatusBarClick", object:nil)
        
        setupAutoSave()

        self.composeView.toContactPicker.contactCollectionView.layoutIfNeeded()
        self.composeView.bccContactPicker.contactCollectionView.layoutIfNeeded()
        self.composeView.ccContactPicker.contactCollectionView.layoutIfNeeded()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "touchStatusBarClick", object:nil)
        
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
        if self.composeView.expirationTimeInterval > 0 {
            if self.composeView.hasOutSideEmails && count(self.encryptionPassword) <= 0 {
                self.composeView.showPasswordAndConfirmDoesntMatch(self.composeView.kExpirationNeedsPWDError)
                return;
            }
        }
        stopAutoSave()
        self.collectDraft()
        self.viewModel.sendMessage()
        
        if presentingViewController != nil {
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            navigationController?.popToRootViewControllerAnimated(true)
        }

    }
    
    @IBAction func cancel_clicked(sender: AnyObject) {
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
            
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            dismiss()
        }
    }
    
    // MARK: - Private methods
    private func setupAutoSave()
    {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(120, target: self, selector: "autoSaveTimer", userInfo: nil, repeats: true)
        self.timer.fire()
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
}




// MARK : - view extensions
extension ComposeEmailViewController : ComposeViewDelegate {
    
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
            self.actualEncryptionStep = EncryptionStep.ConfirmPassword
            self.composeView.showConfirmPasswordView()
            
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
            println("No step defined.")
        }
    }
    
    func composeViewDidTapEncryptedButton(composeView: ComposeView) {
        self.actualEncryptionStep = EncryptionStep.DefinePassword
        self.composeView.showDefinePasswordView()
        self.composeView.hidePasswordAndConfirmDoesntMatch()
    }
    
    func composeViewDidTapAttachmentButton(composeView: ComposeView) {
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
extension ComposeEmailViewController: AttachmentsViewControllerDelegate {
    func attachmentsViewController(attachmentsViewController: AttachmentsViewController, didFinishPickingAttachments attachments: [AnyObject]) {
        self.attachments = attachments
    }
    
    func attachmentsViewController(attachmentsViewController: AttachmentsViewController, didPickedAttachment: UIImage, fileName:String, type:String) -> Void {
        self.collectDraft()
        let attachment = didPickedAttachment.toAttachment(self.viewModel.message!, fileName: fileName, type: type)
        self.viewModel.uploadAtt(attachment)
        
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


