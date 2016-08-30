//
//  SignUpPasswordViewController.swift
//  
//
//  Created by Yanfeng Zhang on 12/18/15.
//
//

import UIKit

class SignUpPasswordViewController: UIViewController {
    
    //define
    private let hidePriority : UILayoutPriority = 1.0;
    private let showPriority: UILayoutPriority = 750.0;
    
    @IBOutlet weak var createPasswordButton: UIButton!
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var passwordTopPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var loginPasswordField: TextInsetTextField!
    @IBOutlet weak var confirmLoginPasswordField: TextInsetTextField!
    
    @IBOutlet weak var mailboxPassword: TextInsetTextField!
    @IBOutlet weak var confirmMailboxPassword: TextInsetTextField!
    
    private let kSegueToEncryptionSetup = "sign_up_password_to_encryption_segue"
    
    var viewModel : SignupViewModel!
    
    private var stopLoading : Bool = false
    
    func configConstraint(show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level
        
        passwordTopPaddingConstraint.priority = level
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginPasswordField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Login Password"), attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        confirmLoginPasswordField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Confirm Login Password"), attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        mailboxPassword.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Mailbox Password"), attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        confirmMailboxPassword.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Confirm Mailbox Password"), attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        
        self.updateButtonStatus()
        
        self.viewModel.fetchDirect { (directs) -> Void in
            
        }
        
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kSegueToEncryptionSetup {
            let viewController = segue.destinationViewController as! EncryptionSetupViewController
            viewController.viewModel = self.viewModel
        }
    }

    @IBAction func backAction(sender: UIButton) {
        stopLoading = true;
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func createPasswordAction(sender: UIButton) {
        dismissKeyboard()
        
        let login_pwd = (loginPasswordField.text ?? "") //.trim()
        let confirm_login_pwd = (confirmLoginPasswordField.text ?? "") //.trim()
        
        let mailbox_pwd = (mailboxPassword.text ?? "") //.trim()
        let confirm_mailbox_pwd = (confirmMailboxPassword.text ?? "") //.trim()
        
        if !login_pwd.isEmpty && confirm_login_pwd == login_pwd {
            if !mailbox_pwd.isEmpty && confirm_mailbox_pwd == mailbox_pwd {
                //create user & login
                viewModel.setPasswords(login_pwd, mailboxPwd: mailbox_pwd)
                self.performSegueWithIdentifier(kSegueToEncryptionSetup, sender: self)
            } else {
                let alert = NSLocalizedString("Mailbox password doesn't match").alertController()
                alert.addOKAction()
                self.presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            let alert = NSLocalizedString("Login password doesn't match").alertController()
            alert.addOKAction()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        updateButtonStatus()
        dismissKeyboard()
    }
    
    func dismissKeyboard() {
        loginPasswordField.resignFirstResponder()
        confirmLoginPasswordField.resignFirstResponder()
        mailboxPassword.resignFirstResponder()
        confirmMailboxPassword.resignFirstResponder()
    }
    
    @IBAction func editingEnd(sender: AnyObject) {
    }
    
    @IBAction func editingChange(sender: AnyObject) {
        updateButtonStatus();
    }
    
    func updateButtonStatus () {
        let login_pwd = (loginPasswordField.text ?? "") //.trim()
        let confirm_login_pwd = (confirmLoginPasswordField.text ?? "") //.trim()
        
        let mailbox_pwd = (mailboxPassword.text ?? "") //.trim()
        let confirm_mailbox_pwd = (confirmMailboxPassword.text ?? "") //.trim()
        
        if !login_pwd.isEmpty && !confirm_login_pwd.isEmpty && !mailbox_pwd.isEmpty && !confirm_mailbox_pwd.isEmpty {
            createPasswordButton.enabled = true
        } else {
            createPasswordButton.enabled = false
        }
    }
}

// MARK: - UITextFieldDelegatesf
extension SignUpPasswordViewController: UITextFieldDelegate {
    func textFieldShouldClear(textField: UITextField) -> Bool {
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        updateButtonStatus()
        if textField == loginPasswordField {
            confirmLoginPasswordField.becomeFirstResponder()
        } else if textField == confirmLoginPasswordField {
            mailboxPassword.becomeFirstResponder()
        } else if textField == mailboxPassword {
            confirmMailboxPassword.becomeFirstResponder()
        } else if textField == confirmMailboxPassword {
            dismissKeyboard()
        }
        return true
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension SignUpPasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        scrollBottomPaddingConstraint.constant = 0.0
        self.configConstraint(false)
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo!
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            scrollBottomPaddingConstraint.constant = keyboardSize.height;
        }
        self.configConstraint(true)
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}