//
//  SignUpViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/13/15.
//  Copyright (c) 2015 ProtonMail Reserach. All rights reserved.
//

import Foundation


class SignUpViewController: UIViewController {
//    @IBOutlet weak var webView: UIWebView!
//    
//    
//    //    let animationDuration: NSTimeInterval = 0.5
//    //    let buttonDisabledAlpha: CGFloat = 0.5
//    //    let keyboardPadding: CGFloat = 12 - 177
//    //
//    //    private let signUpKeySegue = "signUpKeySegue"
//    //
//    //    @IBOutlet weak var keyboardPaddingConstraint: NSLayoutConstraint!
//    //
//    //    @IBOutlet weak var userNameInput: TextInsetTextField!
//    //    @IBOutlet weak var passwordInput: TextInsetTextField!
//    //    @IBOutlet weak var confirmInput: TextInsetTextField!
//    //    @IBOutlet weak var notificationEmail: TextInsetTextField!
//    //    @IBOutlet weak var updateNewsButton: UIButton!
//    //    @IBOutlet weak var signUpButton: UIButton!
//    //    @IBOutlet weak var loadingView: UIView!
//    //    @IBOutlet weak var loadingSpanerView: UIActivityIndicatorView!
//    //    @IBOutlet weak var checkImage: UIImageView!
//    //
//    //    //////
//    //    var isUpdateNews: Bool = true;
//    //    var isUserNameValid: Bool = false;
//    //
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        let recptcha = NSURL(string: "http://protonmail.xyz/recaptcha.html")!
//        
//        let requestObj = NSURLRequest(URL: recptcha)
//        //        [tempWebview loadRequest:requestObj];
//        //        [tempWebview release];
//        webView.loadRequest(requestObj)
//        //        setupButtons()
//        //        setupInputs()
//        //
//        //        updateNewsButton.selected = isUpdateNews
//        //
//        //        loadingSpanerView.stopAnimating()
//        //        checkImage.hidden = true
//        //
//        //        configureNavigationBar()
//        //        setNeedsStatusBarAppearanceUpdate()
//    }
//    
//    @IBAction func checkAction(sender: UIButton) {
//
//        let result = webView.stringByEvaluatingJavaScriptFromString("grecaptcha.getResponse(widgetId1)")
//        if (result != nil) {
//            PMLog.D("\(result)")
//
//            //post function
////            let api = CreateNewUserRequest(token: result!);
////            api.call({ (task, response, hasError) -> Void in
////                    PMLog.D("\(response)")
////                
////                if hasError {
////                    
////                    self.webView.reload()
////                }
////            })
//            //send create function
//        } else {
//            //show error
//        }
//    }
//    
//    
//    func startChecking() -> Void
//    {
//        loadingSpanerView.startAnimating()
//        checkImage.hidden = true
//    }
//    
//    func finishChecking(isOk : Bool)  -> Void
//    {
//        loadingSpanerView.stopAnimating()
//        
//        if isOk {
//            isUserNameValid = true
//            checkImage.image = UIImage(named: "checked")
//        }
//        else
//        {
//            checkImage.image = UIImage(named: "cancel_compose")
//        }
//        
//        checkImage.hidden = false
//    }
//    
//    func checkUserExsit() {
//        if isUserNameValid == false {
//            let userName = userNameInput.text
//            
//            startChecking()
//            
//            sharedUserDataService.checkUserNameIsExsit(userName!){ isExsit, error in
//                if let error = error {
//                    PMLog.D(" error: \(error)")
//                    
//                    let alertController = error.alertController()
//                    alertController.addOKAction()
//                    self.presentViewController(alertController, animated: true, completion: nil)
//                    
//                    self.finishChecking(false)
//                    
//                } else {
//                    self.finishChecking(true)
//                }
//            }
//        }
//    }
//    
//    func updateButton(button: UIButton) {
//        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
//            button.alpha = button.enabled ? 1.0 : self.buttonDisabledAlpha
//        })
//    }
//    
//    func checkInput() -> Bool {
//        if userNameInput.text!.isEmpty {
//            return false;
//        }
//        if passwordInput.text!.isEmpty {
//            return false;
//        }
//        if confirmInput.text!.isEmpty {
//            return false;
//        }
//        if notificationEmail.text!.isEmpty {
//            return false;
//        }
//        return true;
//    }
//    
//    func dismissKeyboard() {
//        userNameInput.resignFirstResponder()
//        passwordInput.resignFirstResponder()
//        confirmInput.resignFirstResponder()
//        notificationEmail.resignFirstResponder()
//    }
//
//    // MARK: - Actions
//    
//    @IBAction func signUpAction(sender: UIButton) {
//        checkUserExsit();
//        signUpUser()
//    }
//    
//    @IBAction func updateMeNewsAction(sender: UIButton) {
//        isUpdateNews = !isUpdateNews
//        updateNewsButton.selected = isUpdateNews
//    }
//    
//    @IBAction func tapAction(sender: UITapGestureRecognizer) {
//        dismissKeyboard();
//    }
//    
//    @IBAction func checkUserExistAction(sender: AnyObject) {
//        signUpUser()
//    }
//}
//
//// MARK: - NSNotificationCenterKeyboardObserverProtocol
//extension SignUpViewController: NSNotificationCenterKeyboardObserverProtocol {
//    func keyboardWillHideNotification(notification: NSNotification) {
//        let keyboardInfo = notification.keyboardInfo
//        
//        keyboardPaddingConstraint.constant = 10
//        
//        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
//            self.view.layoutIfNeeded()
//            }, completion: nil)
//    }
//    
//    func keyboardWillShowNotification(notification: NSNotification) {
//        let keyboardInfo = notification.keyboardInfo
//        
//        keyboardPaddingConstraint.constant = keyboardInfo.beginFrame.height + keyboardPadding
//        
//        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
//            self.view.layoutIfNeeded()
//            }, completion: nil)
//    }
    //
    //    override func viewWillAppear(animated: Bool) {
    //        super.viewWillAppear(animated)
    //        navigationController?.setNavigationBarHidden(false, animated: true)
    //        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
    //    }
    //
    //    override func viewDidAppear(animated: Bool) {
    //        super.viewDidAppear(animated)
    //        dismissKeyboard()
    //    }
    //
    //    override func viewWillDisappear(animated: Bool) {
    //        super.viewWillDisappear(animated)
    //        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    //    }
    //
    //    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
    //        navigationController?.setNavigationBarHidden(true, animated: true)
    //        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    //    }
    //
    //    func setupButtons() {
    //        signUpButton.alpha = buttonDisabledAlpha
    //        signUpButton.roundCorners()
    //    }
    //
    //    func setupInputs()
    //    {
    //        userNameInput.roundCorners()
    //        passwordInput.roundCorners()
    //        confirmInput.roundCorners()
    //        notificationEmail.roundCorners()
    //        loadingView.roundCorners()
    //    }
    //
    //    // MARK: - private methods
    //    func configureNavigationBar() {
    //        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
    //        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Blue_475F77
    //        self.navigationController?.navigationBar.translucent = true
    //        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
    //
    //        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
    //        self.navigationController?.navigationBar.titleTextAttributes = [
    //            NSForegroundColorAttributeName: UIColor.whiteColor(),
    //            NSFontAttributeName: navigationBarTitleFont
    //        ]
    //    }
    //
    //    func signUpUser() {
    //        if(isUserNameValid){
    ////            MBProgressHUD.showHUDAddedTo(view, animated: true)
    ////            sharedUserDataService.createNewUser(userNameInput.text, password: passwordInput.text, email: notificationEmail.text, receive: isUpdateNews) { _, error in
    ////                MBProgressHUD.hideHUDForView(self.view, animated: true)
    ////
    ////                if let error = error {
    ////                    PMLog.D(" error: \(error)")
    ////
    ////                    let alertController = error.alertController()
    ////                    alertController.addOKAction()
    ////
    ////                    self.presentViewController(alertController, animated: true, completion: nil)
    ////                } else {
    ////                    self.performSegueWithIdentifier(self.signUpKeySegue, sender: self)
    ////                }
    ////            }
    //        }
    //        else
    //        {
    //            NSLog("Error log");
    //        }
    //    }
    //
    //
    //    func startChecking() -> Void
    //    {
    //        loadingSpanerView.startAnimating()
    //        checkImage.hidden = true
    //    }
    //
    //    func finishChecking(isOk : Bool)  -> Void
    //    {
    //        loadingSpanerView.stopAnimating()
    //
    //        if isOk {
    //            isUserNameValid = true
    //            checkImage.image = UIImage(named: "checked")
    //        }
    //        else
    //        {
    //            checkImage.image = UIImage(named: "cancel_compose")
    //        }
    //
    //        checkImage.hidden = false
    //    }
    //
    //    func checkUserExsit() {
    //        if isUserNameValid == false {
    //            let userName = userNameInput.text
    //
    //            startChecking()
    //
    //            sharedUserDataService.checkUserNameIsExsit(userName){ isExsit, error in
    //                if let error = error {
    //                    PMLog.D(" error: \(error)")
    //
    //                    let alertController = error.alertController()
    //                    alertController.addOKAction()
    //                    self.presentViewController(alertController, animated: true, completion: nil)
    //
    //                    self.finishChecking(false)
    //
    //                } else {
    //                    self.finishChecking(true)
    //                }
    //            }
    //        }
    //    }
    //
    //    func updateButton(button: UIButton) {
    //        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
    //            button.alpha = button.enabled ? 1.0 : self.buttonDisabledAlpha
    //        })
    //    }
    //
    //    func checkInput() -> Bool {
    //        if userNameInput.text.isEmpty {
    //            return false;
    //        }
    //        if passwordInput.text.isEmpty {
    //            return false;
    //        }
    //        if confirmInput.text.isEmpty {
    //            return false;
    //        }
    //        if notificationEmail.text.isEmpty {
    //            return false;
    //        }
    //        return true;
    //    }
    //
    //    func dismissKeyboard() {
    //        userNameInput.resignFirstResponder()
    //        passwordInput.resignFirstResponder()
    //        confirmInput.resignFirstResponder()
    //        notificationEmail.resignFirstResponder()
    //    }
    //
    //    // MARK: - Actions
    //
    //    @IBAction func signUpAction(sender: UIButton) {
    //        checkUserExsit();
    //        signUpUser()
    //    }
    //
    //    @IBAction func updateMeNewsAction(sender: UIButton) {
    //        isUpdateNews = !isUpdateNews
    //        updateNewsButton.selected = isUpdateNews
    //    }
    //
    //    @IBAction func tapAction(sender: UITapGestureRecognizer) {
    //        dismissKeyboard();
    //    }
    //
    //    @IBAction func checkUserExistAction(sender: AnyObject) {
    //        signUpUser()
    //    }
}

//
//// MARK: - NSNotificationCenterKeyboardObserverProtocol
//extension SignUpViewController: NSNotificationCenterKeyboardObserverProtocol {
//    func keyboardWillHideNotification(notification: NSNotification) {
//        let keyboardInfo = notification.keyboardInfo
//
//        keyboardPaddingConstraint.constant = 10
//
//        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
//            self.view.layoutIfNeeded()
//            }, completion: nil)
//    }
//
//    func keyboardWillShowNotification(notification: NSNotification) {
//        let keyboardInfo = notification.keyboardInfo
//
//        keyboardPaddingConstraint.constant = keyboardInfo.beginFrame.height + keyboardPadding
//
//        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
//            self.view.layoutIfNeeded()
//            }, completion: nil)
//    }
//}
//
//
//// MARK: - UITextFieldDelegate
//extension SignUpViewController: UITextFieldDelegate {
//    func textFieldShouldClear(textField: UITextField) -> Bool {
//        signUpButton.enabled = false
//        updateButton(signUpButton)
//        return true
//    }
//
//    func textFieldDidEndEditing(textField: UITextField) {
//        if textField == userNameInput {
//            checkUserExsit();
//        }
//    }
//    
//    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
//        let text = textField.text as NSString
//        let changedText = text.stringByReplacingCharactersInRange(range, withString: string)
//        
//        if textField == userNameInput {
//            isUserNameValid = false
//        }
//        
//        signUpButton.enabled = checkInput()
//        updateButton(signUpButton)
//        
//        return true
//    }
//    
//    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        
//        if checkInput() {
//            signUpUser()
//        }
//        
//        return true
//    }
//}
//
//// MARK: - UITextFieldDelegate
//extension SignUpViewController: UITextFieldDelegate {
//    func textFieldShouldClear(textField: UITextField) -> Bool {
//        signUpButton.enabled = false
//        updateButton(signUpButton)
//        return true
//    }
//    
//    func textFieldDidEndEditing(textField: UITextField) {
//        if textField == userNameInput {
//            checkUserExsit();
//        }
//    }
//    
//    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
//        let text = textField.text! as NSString
//        let changedText = text.stringByReplacingCharactersInRange(range, withString: string)
//        
//        if textField == userNameInput {
//            isUserNameValid = false
//        }
//        
//        signUpButton.enabled = checkInput()
//        updateButton(signUpButton)
//        
//        return true
//    }
//    
//    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        
//        if checkInput() {
//            signUpUser()
//        }
//        
//        return true
//    }
//}
