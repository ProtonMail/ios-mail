//
//  ComposePasswordViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/24/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


class ComposePasswordViewController: UIViewController {

    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var confirmPasswordErrorLabel: UILabel!
    
    @IBOutlet weak var hintField: UITextField!
    @IBOutlet weak var hintErrorLabel: UILabel!
    
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!

    private let upgradePageUrl = NSURL(string: "https://protonmail.com/upgrade")!
    
    //var viewModel : LabelViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }
    
    //
    
    @IBAction func getMoreInfoAction(sender: UIButton) {
        UIApplication.sharedApplication().openURL(upgradePageUrl)
    }

    @IBAction func closeAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func removeAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func applyAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    
    internal func dismissKeyboard() {
        passwordField.resignFirstResponder()
        confirmPasswordField.resignFirstResponder()
        hintField.resignFirstResponder()
    }
    
}


// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension ComposePasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        scrollBottomPaddingConstraint.constant = 0.0
        //self.configConstraint(false)
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
        //self.configConstraint(true)
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}