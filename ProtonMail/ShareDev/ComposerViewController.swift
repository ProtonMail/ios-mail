//
//  ComposerViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/13/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import UIKit

class ComposerViewController: ZSSRichTextEditor, ViewModelProtocol {
    
    // view model
    fileprivate var viewModel : ComposeViewModel!
    
    func setViewModel(_ vm: Any) {
        self.viewModel = vm as! ComposeViewModel
    }
    
    func inactiveViewModel() {
//        self.stopAutoSave()
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object:nil)
//        
//        self.dismissKeyboard()
//        if self.presentingViewController != nil {
//            self.dismiss(animated: true, completion: nil)
//        } else {
//            let _ = self.navigationController?.popViewController(animated: true)
//        }
    }
    
    // private views
    fileprivate var webView : UIWebView!
    fileprivate var composeView : ComposeView!
    fileprivate var cancelButton: UIBarButtonItem!
    fileprivate var sendButton: UIBarButtonItem!
    
    // private vars
//    fileprivate var timer : Timer!
//    fileprivate var draggin : Bool! = false
    fileprivate var contacts: [ContactVO]! = [ContactVO]()
//    fileprivate var actualEncryptionStep = EncryptionStep.DefinePassword
//    fileprivate var encryptionPassword: String = ""
//    fileprivate var encryptionConfirmPassword: String = ""
//    fileprivate var encryptionPasswordHint: String = ""
//    fileprivate var hasAccessToAddressBook: Bool = false
//
    fileprivate var attachments: [Any]?
//    
//    @IBOutlet weak var expirationPicker: UIPickerView!
//    // offsets
    fileprivate var composeViewSize : CGFloat = 186;

    // MARK : const values
    fileprivate let kNumberOfColumnsInTimePicker: Int = 2
    fileprivate let kNumberOfDaysInTimePicker: Int = 30
    fileprivate let kNumberOfHoursInTimePicker: Int = 24

    fileprivate let kPasswordSegue : String = "to_eo_password_segue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //inital navigation bar items
        self.cancelButton = UIBarButtonItem(title:NSLocalizedString("Cancel", comment: "Action"),
                                            style: .plain,
                                            target: self,
                                            action: #selector(ComposerViewController.cancelButtonTapped(sender:)))
        self.sendButton = UIBarButtonItem(image: UIImage(named:"sent_compose"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(ComposerViewController.saveButtonTapped(sender:)))
        self.navigationItem.leftBarButtonItem = self.cancelButton
        self.navigationItem.rightBarButtonItem = self.sendButton
        
        self.configureNavigationBar()
        
        //inital webview
        self.baseURL = URL( fileURLWithPath: "https://protonmail.ch")
        //self.formatHTML = false
        self.webView = self.getWebView()
        
        // init views
        self.composeView = ComposeView(nibName: "ComposeView", bundle: nil)
        let w = UIScreen.main.applicationFrame.width;
        self.composeView.view.frame = CGRect(x: 0, y: 0, width: w, height: composeViewSize + 60)
        self.composeView.delegate = self
        self.composeView.datasource = self
        self.webView.scrollView.addSubview(composeView.view);
        self.webView.scrollView.bringSubview(toFront: composeView.view)
        
        // update content values
        updateMessageView()
        self.contacts = sharedContactDataService.allContactVOs()
        retrieveAllContacts()
//        
//        self.expirationPicker.alpha = 0.0
//        self.expirationPicker.dataSource = self
//        self.expirationPicker.delegate = self
        
        self.attachments = viewModel.getAttachments()
        
        // update header layous
        updateContentLayout(false)
        
        //change message as read
        self.viewModel.markAsRead();
        
        
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveButtonTapped(sender: UIBarButtonItem) {
        self.hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
            self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
        })
    }
    
    func cancelButtonTapped(sender: UIBarButtonItem) {
        let dismiss: (() -> Void) = {
            self.hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
                let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
                self.extensionContext!.cancelRequest(withError: cancelError)
            })
        }
        
        //if self.viewModel.hasDraft || composeView.hasContent || ((attachments?.count ?? 0) > 0) {
        let alertController = UIAlertController(title: "Confirmation", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Save draft", style: .default, handler: { (action) -> Void in
            //                self.stopAutoSave()
            //                self.collectDraft()
            //                self.viewModel.updateDraft()
            dismiss()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Discard draft", style: .destructive, handler: { (action) -> Void in
            //                self.stopAutoSave()
            //                self.viewModel.deleteDraft()
            dismiss()
        }))
        
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        present(alertController, animated: true, completion: nil)
    }
    
    func hideExtensionWithCompletionHandler(completion:@escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.50, animations: { () -> Void in
            self.navigationController!.view.transform = CGAffineTransform(translationX: 0, y: self.navigationController!.view.frame.size.height)
        }, completion: completion)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // ******************
    func configureNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let navigationBarTitleFont = UIFont.systemFont(ofSize: UIFont.Size.h2)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: navigationBarTitleFont
        ]
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - Private methods
    fileprivate func updateMessageView() {
        self.composeView.updateFromValue(self.viewModel.getDefaultAddress()?.email ?? "", pickerEnabled: true)
        self.composeView.subject.text = self.viewModel.getSubject();
        self.shouldShowKeyboard = false
        self.setHTML(self.viewModel.getHtmlBody())
    }
    
    fileprivate func retrieveAllContacts() {
        sharedContactDataService.getContactVOs { (contacts, error) -> Void in
//            if let error = error as NSError? {
//                PMLog.D(" error: \(error)")
//                
//                let alertController = error.alertController()
//                alertController.addOKAction()
//                
//                self.present(alertController, animated: true, completion: nil)
//            }
//            
//            self.contacts = contacts
//            
//            self.refreshControl.endRefreshing()
//            self.tableView.reloadData()
        }
    }
    
    fileprivate func updateContentLayout(_ animation: Bool) {
        UIView.animate(withDuration: animation ? 0.25 : 0, animations: { () -> Void in
            for subview in self.webView.scrollView.subviews {
                let sub = subview
                if sub == self.composeView.view {
                    continue
                } else if sub is UIImageView {
                    continue
                } else {
                    let h : CGFloat = self.composeViewSize
                    self.updateFooterOffset(h)
                    sub.frame = CGRect(x: sub.frame.origin.x, y: h, width: sub.frame.width, height: sub.frame.height);
                }
            }
        })
    }
}





// MARK : - view extensions
extension ComposerViewController : ComposeViewDelegate {
    func composeViewPickFrom(_ composeView: ComposeView) {
//        if attachments?.count > 0 {
//            let alertController = NSLocalizedString("Please remove all attachments before changing sender!", comment: "Error").alertController()
//            alertController.addOKAction()
//            self.present(alertController, animated: true, completion: nil)
//        } else {
//            var needsShow : Bool = false
//            let alertController = UIAlertController(title: NSLocalizedString("Change sender address to ..", comment: "Title"), message: nil, preferredStyle: .actionSheet)
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action"), style: .cancel, handler: nil))
//            let multi_domains = self.viewModel.getAddresses()
//            let defaultAddr = self.viewModel.getDefaultAddress()
//            for addr in multi_domains {
//                if addr.status == 1 && addr.receive == 1 && defaultAddr != addr {
//                    needsShow = true
//                    alertController.addAction(UIAlertAction(title: addr.email, style: .default, handler: { (action) -> Void in
//                        if let signature = self.viewModel.getCurrrentSignature(addr.address_id) {
//                            self.updateSignature("\(signature)")
//                        }
//                        self.viewModel.updateAddressID(addr.address_id)
//                        self.composeView.updateFromValue(addr.email, pickerEnabled: true)
//                    }))
//                }
//            }
//            if needsShow {
//                alertController.popoverPresentationController?.sourceView = self.composeView.fromView
//                alertController.popoverPresentationController?.sourceRect = self.composeView.fromView.frame
//                present(alertController, animated: true, completion: nil)
//            }
//        }
    }
    
    func ComposeViewDidSizeChanged(_ size: CGSize) {
//        //self.composeSize = size
//        //self.updateViewSize()
//        self.composeViewSize = size.height;
//        let w = UIScreen.main.applicationFrame.width;
//        self.composeView.view.frame = CGRect(x: 0, y: 0, width: w, height: composeViewSize )
//        
//        self.updateContentLayout(true)
    }
    
    func ComposeViewDidOffsetChanged(_ offset: CGPoint){
        //        if ( self.cousorOffset  != offset.y)
        //        {
        //            self.cousorOffset = offset.y
        //            self.updateAutoScroll()
        //        }
    }
    
    func composeViewDidTapNextButton(_ composeView: ComposeView) {
//        switch(actualEncryptionStep) {
//        case EncryptionStep.DefinePassword:
//            self.encryptionPassword = (composeView.encryptedPasswordTextField.text ?? "").trim()
//            if !self.encryptionPassword.isEmpty {
//                self.actualEncryptionStep = EncryptionStep.ConfirmPassword
//                self.composeView.showConfirmPasswordView()
//            } else {
//                self.composeView.showPasswordAndConfirmDoesntMatch(self.composeView.kEmptyEOPWD);
//            }
//        case EncryptionStep.ConfirmPassword:
//            self.encryptionConfirmPassword = (composeView.encryptedPasswordTextField.text ?? "").trim()
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
//            self.encryptionPasswordHint = (composeView.encryptedPasswordTextField.text ?? "").trim()
//            self.actualEncryptionStep = EncryptionStep.DefinePassword
//            self.composeView.showEncryptionDone()
//        default:
//            PMLog.D("No step defined.")
//        }
    }
    
    func composeViewDidTapEncryptedButton(_ composeView: ComposeView) {
        self.performSegue(withIdentifier: kPasswordSegue, sender: self)
        //        self.actualEncryptionStep = EncryptionStep.DefinePassword
        //        self.composeView.showDefinePasswordView()
        //        self.composeView.hidePasswordAndConfirmDoesntMatch()
    }
    
    func composeViewDidTapAttachmentButton(_ composeView: ComposeView) {
//        if let viewController = UIStoryboard.instantiateInitialViewController(storyboard: .attachments) as? UINavigationController {
//            if let attachmentsViewController = viewController.viewControllers.first as? AttachmentsTableViewController {
//                attachmentsViewController.delegate = self
//                attachmentsViewController.message = viewModel.message;
//                if let _ = attachments {
//                    attachmentsViewController.attachments = viewModel.getAttachments() ?? []
//                }
//            }
//            present(viewController, animated: true, completion: nil)
//        }
    }
    
    func composeViewDidTapExpirationButton(_ composeView: ComposeView)
    {
//        self.expirationPicker.alpha = 1;
//        self.view.bringSubview(toFront: expirationPicker)
    }
    
    func composeViewHideExpirationView(_ composeView: ComposeView)
    {
//        self.expirationPicker.alpha = 0;
    }
    
    func composeViewCancelExpirationData(_ composeView: ComposeView)
    {
//        self.expirationPicker.selectRow(0, inComponent: 0, animated: true)
//        self.expirationPicker.selectRow(0, inComponent: 1, animated: true)
    }
    
    func composeViewCollectExpirationData(_ composeView: ComposeView)
    {
//        let selectedDay = expirationPicker.selectedRow(inComponent: 0)
//        let selectedHour = expirationPicker.selectedRow(inComponent: 1)
//        if self.composeView.setExpirationValue(selectedDay, hour: selectedHour)
//        {
//            self.expirationPicker.alpha = 0;
//        }
    }
    
    func composeView(_ composeView: ComposeView, didAddContact contact: ContactVO, toPicker picker: MBContactPicker)
    {
//        if (picker == composeView.toContactPicker) {
//            self.viewModel.toSelectedContacts.append(contact)
//        } else if (picker == composeView.ccContactPicker) {
//            self.viewModel.ccSelectedContacts.append(contact)
//        } else if (picker == composeView.bccContactPicker) {
//            self.viewModel.bccSelectedContacts.append(contact)
//        }
    }
    
    func composeView(_ composeView: ComposeView, didRemoveContact contact: ContactVO, fromPicker picker: MBContactPicker)
    {// here each logic most same, need refactor later
//        if (picker == composeView.toContactPicker) {
//            var contactIndex = -1
//            let selectedContacts = self.viewModel.toSelectedContacts
//            for (index, selectedContact) in (selectedContacts?.enumerated())! {
//                if (contact.email == selectedContact.email) {
//                    contactIndex = index
//                }
//            }
//            if (contactIndex >= 0) {
//                self.viewModel.toSelectedContacts.remove(at: contactIndex)
//            }
//        } else if (picker == composeView.ccContactPicker) {
//            var contactIndex = -1
//            let selectedContacts = self.viewModel.ccSelectedContacts
//            for (index, selectedContact) in (selectedContacts?.enumerated())! {
//                if (contact.email == selectedContact.email) {
//                    contactIndex = index
//                }
//            }
//            if (contactIndex >= 0) {
//                self.viewModel.ccSelectedContacts.remove(at: contactIndex)
//            }
//        } else if (picker == composeView.bccContactPicker) {
//            var contactIndex = -1
//            let selectedContacts = self.viewModel.bccSelectedContacts
//            for (index, selectedContact) in (selectedContacts?.enumerated())! {
//                if (contact.email == selectedContact.email) {
//                    contactIndex = index
//                }
//            }
//            if (contactIndex >= 0) {
//                self.viewModel.bccSelectedContacts.remove(at: contactIndex)
//            }
//        }
    }
}


// MARK : compose data source
extension ComposerViewController : ComposeViewDataSource {
    
    func composeViewContactsModelForPicker(_ composeView: ComposeView, picker: MBContactPicker) -> [Any]! {
        return contacts
    }
    
    func composeViewSelectedContactsForPicker(_ composeView: ComposeView, picker: MBContactPicker) ->  [Any]! {
        var selectedContacts: [ContactVO] = [ContactVO]()
//        if (picker == composeView.toContactPicker) {
//            selectedContacts = self.viewModel.toSelectedContacts
//        } else if (picker == composeView.ccContactPicker) {
//            selectedContacts = self.viewModel.ccSelectedContacts
//        } else if (picker == composeView.bccContactPicker) {
//            selectedContacts = self.viewModel.bccSelectedContacts
//        }
        return selectedContacts
    }
}

