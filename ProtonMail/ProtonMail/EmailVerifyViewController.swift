//
//  EmailVerifyViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/1/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import UIKit

class EmailVerifyViewController: UIViewController, SignupViewModelDelegate {
    
    
    @IBOutlet weak var emailTextField: TextInsetTextField!
    @IBOutlet weak var verifyCodeTextField: TextInsetTextField!
    
    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var warningIcon: UIImageView!
    
    @IBOutlet weak var titleTwoLabel: UILabel!
    
    @IBOutlet weak var sendCodeButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    
    //define
    private let hidePriority : UILayoutPriority = 1.0;
    private let showPriority: UILayoutPriority = 750.0;
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var userNameTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    
    private let kSegueToNotificationEmail = "sign_up_pwd_email_segue"
    private var startVerify : Bool = false
    private var checkUserStatus : Bool = false
    private var stopLoading : Bool = false
    var viewModel : SignupViewModel!
    
    private var doneClicked : Bool = false
    
    private var timer : NSTimer!
    
    func configConstraint(show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level
        
        userNameTopPaddingConstraint.priority = level
        
        titleTwoLabel.hidden = show
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email address", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        verifyCodeTextField.attributedPlaceholder = NSAttributedString(string: "Enter Verification Code", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        
        self.updateButtonStatus()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default;
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
        self.viewModel.setDelegate(self)
        //register timer
        self.startAutoFetch()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
        self.viewModel.setDelegate(nil)
        //unregister timer
        self.stopAutoFetch()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func verificationCodeChanged(viewModel: SignupViewModel, code: String!) {
        verifyCodeTextField.text = code
    }
    
    private func startAutoFetch()
    {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "countDown", userInfo: nil, repeats: true)
        self.timer.fire()
    }
    private func stopAutoFetch()
    {
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
    }
    
    func countDown() {
        let count = self.viewModel.getTimerSet()
        UIView.performWithoutAnimation { () -> Void in
            if count != 0 {
                self.sendCodeButton.setTitle("Retry after \(count) seconds", forState: UIControlState.Normal)
            } else {
                self.sendCodeButton.setTitle(NSLocalizedString("Send Verification Code"), forState: UIControlState.Normal)
            }
            self.sendCodeButton.layoutIfNeeded()
        }
        updateButtonStatus()
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kSegueToNotificationEmail {
            let viewController = segue.destinationViewController as! SignUpEmailViewController
            viewController.viewModel = self.viewModel
        }
    }
    
    @IBAction func backAction(sender: UIButton) {
        stopLoading = true
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func sendCodeAction(sender: UIButton) {
        let emailaddress = emailTextField.text
        MBProgressHUD.showHUDAddedTo(view, animated: true)
        viewModel.setCodeEmail(emailaddress)
        self.viewModel.sendVerifyCode (.email) { (isOK, error) -> Void in
            MBProgressHUD.hideHUDForView(self.view, animated: true)
            if !isOK {
                var alert :  UIAlertController!
                var title = NSLocalizedString("Verification code request failed")
                var message = ""
                if error?.code == 12201 { //USER_CODE_EMAIL_INVALID = 12201
                    title = NSLocalizedString("Email address invalid")
                    message = NSLocalizedString("Please input a valid email address.")
                } else {
                    message = error!.localizedDescription
                }
                alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                alert.addOKAction()
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: NSLocalizedString("Verification code sent"), message: NSLocalizedString("Please check your email for the verification code."), preferredStyle: .Alert)
                alert.addOKAction()
                self.presentViewController(alert, animated: true, completion: nil)
            }
            println("\(isOK),   \(error)")
        }
    }
    
    @IBAction func verifyCodeAction(sender: UIButton) {
        dismissKeyboard()
        
        if doneClicked {
            return
        }
        doneClicked = true;
        MBProgressHUD.showHUDAddedTo(view, animated: true)
        dismissKeyboard()
        viewModel.setEmailVerifyCode(verifyCodeTextField.text)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.viewModel.createNewUser { (isOK, createDone, message, error) -> Void in
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                self.doneClicked = false
                if !message.isEmpty {
                    var alert :  UIAlertController!
                    var title = NSLocalizedString("Create user failed")
                    var message = ""
                    if error?.code == 12081 { //USER_CREATE_NAME_INVALID = 12081
                        title = NSLocalizedString("User name invalid")
                        message = NSLocalizedString("Please try a different user name.")
                    } else if error?.code == 12082 { //USER_CREATE_PWD_INVALID = 12082
                        title = NSLocalizedString("Account password invalid")
                        message = NSLocalizedString("Please try a different password.")
                    } else if error?.code == 12083 { //USER_CREATE_EMAIL_INVALID = 12083
                        title = NSLocalizedString("The verification email invalid")
                        message = NSLocalizedString("Please try a different email address.")
                    } else if error?.code == 12084 { //USER_CREATE_EXISTS = 12084
                        title = NSLocalizedString("User name exist")
                        message = NSLocalizedString("Please try a different user name.")
                    } else if error?.code == 12085 { //USER_CREATE_DOMAIN_INVALID = 12085
                        title = NSLocalizedString("Email domain invalid")
                        message = NSLocalizedString("Please try a different domain.")
                    } else if error?.code == 12087 { //USER_CREATE_TOKEN_INVALID = 12087
                        title = NSLocalizedString("Wrong verification code")
                        message = NSLocalizedString("Please try again.")
                    } else {
                        message = error!.localizedDescription
                    }
                    alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                    alert.addOKAction()
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    if isOK || createDone {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.performSegueWithIdentifier(self.kSegueToNotificationEmail, sender: self)
                        })
                    }
                }
            }
        })
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        updateButtonStatus()
        dismissKeyboard()
    }
    func dismissKeyboard() {
        emailTextField.resignFirstResponder()
        verifyCodeTextField.resignFirstResponder()
    }
    
    @IBAction func editEnd(sender: UITextField) {

    }
    
    @IBAction func editingChanged(sender: AnyObject) {
        updateButtonStatus();
    }
    
    func updateButtonStatus() {
        let emailaddress = emailTextField.text
        //need add timer
        if emailaddress.isEmpty || self.viewModel.getTimerSet() > 0 {
            sendCodeButton.enabled = false
        } else {
            sendCodeButton.enabled = true
        }
        
        let verifyCode = verifyCodeTextField.text
        if verifyCode.isEmpty {
            continueButton.enabled = false
        } else {
            continueButton.enabled = true
        }
    }
}

// MARK: - UITextFieldDelegatesf
extension EmailVerifyViewController: UITextFieldDelegate {
    func textFieldShouldClear(textField: UITextField) -> Bool {
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        updateButtonStatus()
        dismissKeyboard()
        return true
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension EmailVerifyViewController: NSNotificationCenterKeyboardObserverProtocol {
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
