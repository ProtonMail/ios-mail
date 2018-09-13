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
        recoveryEmailField.attributedPlaceholder = NSAttributedString(string: LocalString._recovery_email,
                                                                      attributes:[NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#9898a8")])
        displayNameField.attributedPlaceholder = NSAttributedString(string: LocalString._settings_display_name_title,
                                                                    attributes:[NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#9898a8")])
        
        topLeftButton.setTitle(LocalString._general_back_action, for: .normal)
        topTitleLabel.text = LocalString._congratulations
        titleWarningLabel.text = LocalString._your_new_secure_email_account_is_ready
        optionalOneLabel.text = LocalString._signup_optional_text
        displayNameNoteLabel.text = LocalString._send_an_email_this_name_that_appears_in_sender_field
        optionalTwoLabel.text = LocalString._signup_optional_text
        
        recoveryEmailNoteLabel.text = LocalString._the_optional_recovery_email_address_allows_you_to_reset_your_login_password_if_you_forget_it
        checkButton.setTitle(LocalString._keep_me_updated_about_new_features, for: .normal)
        goInboxButton.setTitle(LocalString._go_to_inbox, for: .normal)
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
                title: LocalString._recovery_email_warning,
                message: LocalString._warning_did_not_set_a_recovery_email_so_account_recovery_is_impossible,
                preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .default, handler: { action in
                
            }))
            alertController.addAction(UIAlertAction(title: LocalString._general_confirm_action, style: .destructive, handler: { action in
                if (!email.isEmpty && !email.isValidEmail()) {
                    let alert = LocalString._please_input_a_valid_email_address.alertController()
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
                let alert = LocalString._please_input_a_valid_email_address.alertController()
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
//        if let addresses = sharedUserDataService.userInfo?.userAddresses.toPMNAddresses() {
//            sharedOpenPGP.setAddresses(addresses);
//        }
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
        if let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            scrollBottomPaddingConstraint.constant = keyboardSize.height;
        }
        self.configConstraint(true)
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}
