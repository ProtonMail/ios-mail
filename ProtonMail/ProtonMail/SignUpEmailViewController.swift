//
//  SignUpEmailViewController.swift
//  
//
//  Created by Yanfeng Zhang on 12/18/15.
//
//

import UIKit
import Fabric
import Crashlytics
import MBProgressHUD

class SignUpEmailViewController: UIViewController {
    
    //define
    fileprivate let hidePriority : UILayoutPriority = UILayoutPriority(rawValue: 1.0);
    fileprivate let showPriority: UILayoutPriority = UILayoutPriority(rawValue: 750.0);
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var recoveryEmailTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var recoveryEmailField: TextInsetTextField!
    @IBOutlet weak var displayNameField: TextInsetTextField!
    
    @IBOutlet weak var titleWarningLabel: UILabel!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var topLeftButton: UIButton!
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var displayNameNoteLabel: UILabel!
    @IBOutlet weak var optionalOneLabel: UILabel!
    @IBOutlet weak var optionalTwoLabel: UILabel!
    @IBOutlet weak var recoveryEmailNoteLabel: UILabel!
    @IBOutlet weak var goInboxButton: UIButton!
    
    var viewModel : SignupViewModel!
    
    func configConstraint(_ show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level

        recoveryEmailTopPaddingConstraint.priority = level
        
        titleWarningLabel.isHidden = show
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userCachedStatus.showTourNextTime()
        recoveryEmailField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Recovery Email", comment: "Title"),
                                                                      attributes:[NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#9898a8")])
        displayNameField.attributedPlaceholder = NSAttributedString(string: LocalString._settings_display_name_title,
                                                                    attributes:[NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#9898a8")])
        
        topLeftButton.setTitle(NSLocalizedString("Back", comment: "top left back button"), for: .normal)
        topTitleLabel.text = NSLocalizedString("Congratulations!", comment: "view top title")
        titleWarningLabel.text = NSLocalizedString("Your new secure email\r\n account is ready.", comment: "view top title")
        optionalOneLabel.text = LocalString._signup_optional_text
        displayNameNoteLabel.text = NSLocalizedString("When you send an email, this is the name that appears in the sender field.", comment: "display name notes")
        optionalTwoLabel.text = LocalString._signup_optional_text
        
        recoveryEmailNoteLabel.text = NSLocalizedString("The optional recovery email address allows you to reset your login password if you forget it.", comment: "recovery email notes")
        checkButton.setTitle(NSLocalizedString("Keep me updated about new features", comment: "Title"), for: .normal)
        goInboxButton.setTitle(NSLocalizedString("Go to inbox", comment: "Action"), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        NotificationCenter.default.addKeyboardObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

    @IBAction func checkAction(_ sender: UIButton) {
        checkButton.isSelected = !checkButton.isSelected
    }

    @IBAction func backAction(_ sender: UIButton) {
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    fileprivate var doneClicked : Bool = false
    @IBAction func doneAction(_ sender: UIButton) {
        let email = (recoveryEmailField.text ?? "").trim()
        if email.isEmpty {
            // show a warning
            let alertController = UIAlertController(
                title: NSLocalizedString("Recovery Email Warning", comment: "Title"),
                message: NSLocalizedString("Warning: You did not set a recovery email so account recovery is impossible if you forget your password. Proceed without recovery email?", comment: "Description"),
                preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .default, handler: { action in
                
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Confirm", comment: "Title"), style: .destructive, handler: { action in
                if (!email.isEmpty && !email.isValidEmail()) {
                    let alert = NSLocalizedString("Please input a valid email address.", comment: "Description").alertController()
                    alert.addOKAction()
                    self.present(alert, animated: true, completion: nil)
                } else {
                    if self.doneClicked {
                        return
                    }
                    self.doneClicked = true
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                    self.dismissKeyboard()
                    self.viewModel.setRecovery(self.checkButton.isSelected, email: self.recoveryEmailField.text!, displayName: self.displayNameField.text!)
                    DispatchQueue.main.async(execute: { () -> Void in
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.doneClicked = false
                        self.moveToInbox()
                    })
                }
            }))
            self.present(alertController, animated: true, completion: nil)
        } else {
            if (!email.isValidEmail()) {
                let alert = NSLocalizedString("Please input a valid email address.", comment: "Description").alertController()
                alert.addOKAction()
                self.present(alert, animated: true, completion: nil)
            } else {
                if self.doneClicked {
                    return
                }
                self.doneClicked = true
                MBProgressHUD.showAdded(to: self.view, animated: true)
                self.dismissKeyboard()
                self.viewModel.setRecovery(self.checkButton.isSelected, email: self.recoveryEmailField.text!, displayName: self.displayNameField.text!)
                DispatchQueue.main.async(execute: { () -> Void in
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.doneClicked = false
                    self.moveToInbox()
                })
            }
        }
    }
    
    fileprivate func moveToInbox() {
        sharedUserDataService.isSignedIn = true
        if let addresses = sharedUserDataService.userInfo?.userAddresses.toPMNAddresses() {
            sharedOpenPGP.setAddresses(addresses);
        }
        self.loadContent()
    }
    
    fileprivate func loadContent() {
        logUser()
        userCachedStatus.pinFailedCount = 0;
        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignIn), object: self)
        (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
        loadContactsAfterInstall()
    }
    
    func logUser() {
        if  let username = sharedUserDataService.username {
            Crashlytics.sharedInstance().setUserIdentifier(username)
            Crashlytics.sharedInstance().setUserName(username)
        }
    }
    
    func loadContactsAfterInstall()
    {
        sharedUserDataService.fetchUserInfo().done() { _ in }.catch { _ in }
        sharedContactDataService.fetchContacts { (contacts, error) in
            if error != nil {
                PMLog.D("\(String(describing: error))")
            } else {
                PMLog.D("Contacts count: \(contacts!.count)")
            }
        }
    }

    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    func dismissKeyboard() {
        recoveryEmailField.resignFirstResponder()
    }
}


// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension SignUpEmailViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        scrollBottomPaddingConstraint.constant = 0.0
        self.configConstraint(false)
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            scrollBottomPaddingConstraint.constant = keyboardSize.height;
        }
        self.configConstraint(true)
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}
