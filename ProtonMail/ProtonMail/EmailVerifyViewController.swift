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
    
    private let kSegueToSignUpPassword = "sign_up_password_segue"
    private var startVerify : Bool = false
    private var checkUserStatus : Bool = false
    private var stopLoading : Bool = false
    var viewModel : SignupViewModel!
    
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
        resetChecking()
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email address", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
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
        if segue.identifier == kSegueToSignUpPassword {
            let viewController = segue.destinationViewController as! SignUpPasswordViewController
            viewController.viewModel = self.viewModel
        }
    }
    
    @IBAction func backAction(sender: UIButton) {
        stopLoading = true
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func startChecking() {
        warningView.hidden = false
        warningLabel.textColor = UIColor(hexString: "A2C173", alpha: 1.0)
        warningLabel.text = "Checking ...."
        warningIcon.hidden = true;
    }
    
    func resetChecking() {
        checkUserStatus = false
        warningView.hidden = true
        warningLabel.textColor = UIColor(hexString: "A2C173", alpha: 1.0)
        warningLabel.text = ""
        warningIcon.hidden = true;
    }
    
    func finishChecking(isOk : Bool) {
        if isOk {
            checkUserStatus = true
            warningView.hidden = false
            warningLabel.textColor = UIColor(hexString: "A2C173", alpha: 1.0)
            warningLabel.text = "UserName is avliable!"
            warningIcon.hidden = false;
        } else {
            warningView.hidden = false
            warningLabel.textColor = UIColor.redColor()
            warningLabel.text = "UserName not avliable!"
            warningIcon.hidden = true;
        }
    }
    
    @IBAction func sendCodeAction(sender: UIButton) {
        
        let emailaddress = emailTextField.text
        
        viewModel.setRecovery(false, email: emailaddress)
       
        self.viewModel.sendVerifyCode { (isOK, error) -> Void in
            
            println("\(isOK),   \(error)")
        }
    }
    
    @IBAction func verifyCodeAction(sender: UIButton) {
        
    }
    
//    @IBAction func createAccountAction(sender: UIButton) {
//        dismissKeyboard()
//        if viewModel.isTokenOk() {
//            if checkUserStatus {
//            } else {
//                let userName = usernameTextField.text
//                if !userName.isEmpty {
//                    startChecking()
//                    viewModel.checkUserName(userName, complete: { (isOk, error) -> Void in
//                        if error != nil {
//                            self.finishChecking(false)
//                        } else {
//                            if isOk {
//                                self.finishChecking(true)
//                            } else {
//                                self.finishChecking(false)
//                            }
//                        }
//                    })
//                } else {
//                    let alert = "The UserName can't empty!".alertController()
//                    alert.addOKAction()
//                    self.presentViewController(alert, animated: true, completion: nil)
//                }
//            }
//        } else {
//            let alert = "The verification failed!".alertController()
//            alert.addOKAction()
//            self.presentViewController(alert, animated: true, completion: nil)
//        }
//    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    func dismissKeyboard() {
        emailTextField.resignFirstResponder()
    }
    
    @IBAction func editEnd(sender: UITextField) {
//        if !stopLoading {
//            if !checkUserStatus {
//                let userName = emailTextField.text
//                if !userName.isEmpty {
//                    startChecking()
//                    viewModel.checkUserName(userName, complete: { (isOk, error) -> Void in
//                        if error != nil {
//                            self.finishChecking(false)
//                        } else {
//                            if isOk {
//                                self.finishChecking(true)
//                            } else {
//                                self.finishChecking(false)
//                            }
//                        }
//                    })
//                } else {
//                    
//                }
//            }
//        }
    }
    
    @IBAction func editingChanged(sender: AnyObject) {
        resetChecking()
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
