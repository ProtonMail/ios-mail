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
    
    @IBOutlet weak var titleOneLabel: UILabel!
    @IBOutlet weak var titleTwoLabel: UILabel!
    
    
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
    
    func configConstraint(show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level
        
        userNameTopPaddingConstraint.priority = level
        
        titleOneLabel.hidden = show
        titleTwoLabel.hidden = show
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email address", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        verifyCodeTextField.attributedPlaceholder = NSAttributedString(string: "Enter Verification Code", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default;
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
        
        self.viewModel.setDelegate(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
        
        self.viewModel.setDelegate(nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func verificationCodeChanged(viewModel: SignupViewModel, code: String!) {
        verifyCodeTextField.text = code
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
        self.viewModel.sendVerifyCode { (isOK, error) -> Void in
            MBProgressHUD.hideHUDForView(self.view, animated: true)
            if !isOK {
                let alert = error!.alertController()
                alert.addOKAction()
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                let alert = "Please check your email!".alertController()
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
        viewModel.setVerifyCode(verifyCodeTextField.text)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.viewModel.createNewUser { (isOK, createDone, message, error) -> Void in
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                self.doneClicked = false
                if !message.isEmpty {
                    let alert = message.alertController()
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
        dismissKeyboard()
    }
    func dismissKeyboard() {
        emailTextField.resignFirstResponder()
        verifyCodeTextField.resignFirstResponder()
    }
    
    @IBAction func editEnd(sender: UITextField) {

    }
    
    @IBAction func editingChanged(sender: AnyObject) {
        
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
