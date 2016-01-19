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
        
        loginPasswordField.attributedPlaceholder = NSAttributedString(string: "Login Password", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        confirmLoginPasswordField.attributedPlaceholder = NSAttributedString(string: "Confirm Login Password", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        mailboxPassword.attributedPlaceholder = NSAttributedString(string: "Mailbox Password", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        confirmMailboxPassword.attributedPlaceholder = NSAttributedString(string: "Confirm Mailbox Password", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
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
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func backAction(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func createPasswordAction(sender: UIButton) {
        self.performSegueWithIdentifier("sign_up_pwd_email_segue", sender: self)
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    
    func dismissKeyboard() {
        loginPasswordField.resignFirstResponder()
        confirmLoginPasswordField.resignFirstResponder()
        mailboxPassword.resignFirstResponder()
        confirmMailboxPassword.resignFirstResponder()
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