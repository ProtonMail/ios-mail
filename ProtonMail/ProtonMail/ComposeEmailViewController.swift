//
//  HtmlEditorViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/21/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit


class ComposeEmailViewController: ZSSRichTextEditor {
    
    var webView : UIWebView!
    private var composeView : ComposeView!
    
    private var composeViewSize : CGFloat = 122;
    
    private var contacts: [ContactVO]! = [ContactVO]()
    var viewModel : ComposeViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.baseURL = NSURL( fileURLWithPath: "https://protonmail.ch")
        self.webView = self.getWebView()
        
        configureNavigationBar()
        setNeedsStatusBarAppearanceUpdate()
        
        //
        self.composeView = ComposeView(nibName: "ComposeView", bundle: nil)
        let w = UIScreen.mainScreen().applicationFrame.width;
        self.composeView.view.frame = CGRect(x: 0, y: 0, width: w, height: composeViewSize + 60)
        self.composeView.delegate = self
        self.composeView.datasource = self
        //self.composeView.view.backgroundColor = UIColor.yellowColor()
        
        self.webView.scrollView.addSubview(composeView.view);
        self.webView.scrollView.bringSubviewToFront(composeView.view)
        
        //self.updateMessageView()
        
        self.contacts = sharedContactDataService.allContactVOs()
        self.composeView.toContactPicker.reloadData()
        self.composeView.ccContactPicker.reloadData()
        self.composeView.bccContactPicker.reloadData()
        
        updateContentLayout(false)
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarHit:", name: "touchStatusBarClick", object:nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "touchStatusBarClick", object:nil)
    }
    
    internal func statusBarHit (notify: NSNotification) {
        webView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func configureNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Blue_475F77
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: navigationBarTitleFont
        ]
    }
    
    func setBody (body : String ) {
        self.setHTML(body)
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
        
    }
    
    @IBAction func cancel_clicked(sender: AnyObject) {
        
        let dismiss: (() -> Void) = {
            // if self.viewModel.messageAction == ComposeMessageAction.OpenDraft {
            self.navigationController?.popViewControllerAnimated(true)
            // } else {
            self.dismissViewControllerAnimated(true, completion: nil)
            // }
        }
        
        //        if self.viewModel.hasDraft || composeView.hasContent || ((attachments?.count ?? 0) > 0) {
        //            let alertController = UIAlertController(title: NSLocalizedString("Confirmation"), message: nil, preferredStyle: .ActionSheet)
        //            alertController.addAction(UIAlertAction(title: NSLocalizedString("Save draft"), style: .Default, handler: { (action) -> Void in
        //                self.stopAutoSave()
        //                self.collectDraft()
        //                self.viewModel.updateDraft()
        //                dismiss()
        //            }))
        //            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
        //            alertController.addAction(UIAlertAction(title: NSLocalizedString("Discard draft"), style: .Destructive, handler: { (action) -> Void in
        //                self.stopAutoSave()
        //                self.viewModel.deleteDraft()
        //                dismiss()
        //            }))
        //
        //            presentViewController(alertController, animated: true, completion: nil)
        //        } else {
        dismiss()
        //        }
        
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
        //        switch(actualEncryptionStep) {
        //        case EncryptionStep.DefinePassword:
        //            self.encryptionPassword = composeView.encryptedPasswordTextField.text ?? ""
        //            self.actualEncryptionStep = EncryptionStep.ConfirmPassword
        //            self.composeView.showConfirmPasswordView()
        //
        //        case EncryptionStep.ConfirmPassword:
        //            self.encryptionConfirmPassword = composeView.encryptedPasswordTextField.text ?? ""
        //
        //            if (self.encryptionPassword == self.encryptionConfirmPassword) {
        //                self.actualEncryptionStep = EncryptionStep.DefineHintPassword
        //                self.composeView.hidePasswordAndConfirmDoesntMatch()
        //                self.composeView.showPasswordHintView()
        //            } else {
        //                self.composeView.showPasswordAndConfirmDoesntMatch(self.composeView.kConfirmError)
        //            }
        //
        //        case EncryptionStep.DefineHintPassword:
        //            self.encryptionPasswordHint = composeView.encryptedPasswordTextField.text ?? ""
        //            self.actualEncryptionStep = EncryptionStep.DefinePassword
        //            self.composeView.showEncryptionDone()
        //        default:
        //            println("No step defined.")
        //        }
    }
    
    func composeViewDidTapEncryptedButton(composeView: ComposeView) {
        //        self.actualEncryptionStep = EncryptionStep.DefinePassword
        //        self.composeView.showDefinePasswordView()
        //        self.composeView.hidePasswordAndConfirmDoesntMatch()
    }
    
    func composeViewDidTapAttachmentButton(composeView: ComposeView) {
        //        if let viewController = UIStoryboard.instantiateInitialViewController(storyboard: .attachments) as? UINavigationController {
        //            if let attachmentsViewController = viewController.viewControllers.first as? AttachmentsViewController {
        //                attachmentsViewController.delegate = self
        //                if let attachments = attachments {
        //                    attachmentsViewController.attachments = attachments
        //
        //                }
        //            }
        //            presentViewController(viewController, animated: true, completion: nil)
        //        }
        
    }
    
    func composeViewDidTapExpirationButton(composeView: ComposeView)
    {
        //self.expirationPicker.alpha = 1;
    }
    
    func composeViewHideExpirationView(composeView: ComposeView)
    {
        //self.expirationPicker.alpha = 0;
    }
    
    func composeViewCancelExpirationData(composeView: ComposeView)
    {
        //self.expirationPicker.selectRow(0, inComponent: 0, animated: true)
        //self.expirationPicker.selectRow(0, inComponent: 1, animated: true)
    }
    
    func composeViewCollectExpirationData(composeView: ComposeView)
    {
        //        let selectedDay = expirationPicker.selectedRowInComponent(0)
        //        let selectedHour = expirationPicker.selectedRowInComponent(1)
        //        if self.composeView.setExpirationValue(selectedDay, hour: selectedHour)
        //        {
        //            self.expirationPicker.alpha = 0;
        //        }
    }
    
    func composeView(composeView: ComposeView, didAddContact contact: ContactVO, toPicker picker: MBContactPicker)
    {
        var selectedContacts: [ContactVO] = [ContactVO]()
        
        if (picker == composeView.toContactPicker) {
            selectedContacts = self.viewModel.toSelectedContacts
        } else if (picker == composeView.ccContactPicker) {
            selectedContacts = self.viewModel.ccSelectedContacts
        } else if (picker == composeView.bccContactPicker) {
            selectedContacts = self.viewModel.bccSelectedContacts
        }
        
        selectedContacts.append(contact)
        
    }
    
    func composeView(composeView: ComposeView, didRemoveContact contact: ContactVO, fromPicker picker: MBContactPicker)
    {
        var contactIndex = -1
        
        var selectedContacts: [ContactVO] = [ContactVO]()
        
        if (picker == composeView.toContactPicker) {
            selectedContacts = self.viewModel.toSelectedContacts
        } else if (picker == composeView.ccContactPicker) {
            selectedContacts = self.viewModel.ccSelectedContacts
        } else if (picker == composeView.bccContactPicker) {
            selectedContacts = self.viewModel.bccSelectedContacts
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
