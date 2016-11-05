//
//  ChangePasswordViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ProtonMail. All rights reserved.
//

import UIKit

class ChangePasswordViewController: UIViewController {
    
    @IBOutlet weak var currentPwdEditor: UITextField!
    @IBOutlet weak var newPwdEditor: UITextField!
    @IBOutlet weak var confirmPwdEditor: UITextField!
    
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var labelOne: UILabel!
    @IBOutlet weak var labelTwo: UILabel!
    @IBOutlet weak var labelThree: UILabel!
    
    @IBOutlet weak var topOffset: NSLayoutConstraint!
    
    var keyboardHeight : CGFloat = 0.0;
    var textFieldPoint : CGFloat = 0.0;
    
    let kAsk2FASegue = "password_to_twofa_code_segue"
    
    private var doneButton: UIBarButtonItem!
    private var viewModel : ChangePWDViewModel!
    func setViewModel(vm:ChangePWDViewModel) -> Void
    {
        self.viewModel = vm
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doneButton = self.editButtonItem()
        doneButton.target = self;
        doneButton.action = #selector(ChangePasswordViewController.doneAction(_:))
        doneButton.title = "Done"
        
        self.navigationItem.title = viewModel.getNavigationTitle()
        self.titleLable.text = viewModel.getSectionTitle()
        self.labelOne.text = viewModel.getLabelOne()
        self.labelTwo.text = viewModel.getLabelTwo()
        self.labelThree.text = viewModel.getLabelThree()
        
        focusFirstEmpty();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: privat methods
    private func dismissKeyboard() {
        if (self.currentPwdEditor != nil) {
            self.currentPwdEditor.resignFirstResponder()
        }
        if (self.newPwdEditor != nil) {
            self.newPwdEditor.resignFirstResponder()
        }
        if (self.confirmPwdEditor != nil) {
            self.confirmPwdEditor.resignFirstResponder()
        }
    }
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }

    func updateView() {
        let screenHeight = view.frame.height;
        let offbox = screenHeight - textFieldPoint
        if offbox > keyboardHeight {
            topOffset.constant = 8;
        } else {
            topOffset.constant = offbox - keyboardHeight;
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kAsk2FASegue {
            let popup = segue.destinationViewController as! TwoFACodeViewController
            popup.delegate = self
            popup.mode = .TwoFactorCode
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        }
    }
    
    internal func setPresentationStyleForSelfController(selfController : UIViewController,  presentingController: UIViewController)
    {
        presentingController.providesPresentationContextTransitionStyle = true;
        presentingController.definesPresentationContext = true;
        presentingController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
    }


    
    @IBAction func StartEditing(sender: UITextField) {
        let frame = sender.convertRect(sender.frame, toView: self.view)
        textFieldPoint = frame.origin.y + frame.height + 40;
        updateView();
    }
    
    private func isInputEmpty() -> Bool {
        let cPwd = (currentPwdEditor.text ?? "") //.trim()
        let nPwd = (newPwdEditor.text ?? "") //.trim()
        let cnPwd = (confirmPwdEditor.text ?? "") //.trim()
        if !cPwd.isEmpty {
            return false;
        }
        if !nPwd.isEmpty {
            return false;
        }
        if !cnPwd.isEmpty {
            return false;
        }
        return true;
    }
    
    private func focusFirstEmpty() -> Void {
        let cPwd = (currentPwdEditor.text ?? "") //.trim()
        let nPwd = (newPwdEditor.text ?? "") //.trim()
        let cnPwd = (confirmPwdEditor.text ?? "") //.trim()
        if cPwd.isEmpty {
            currentPwdEditor.becomeFirstResponder()
        }
        else if nPwd.isEmpty {
            newPwdEditor.becomeFirstResponder()
        }
        else if cnPwd.isEmpty {
            confirmPwdEditor.becomeFirstResponder()
        }
    }
    
    var cached2faCode : String?
    private func startUpdatePwd () -> Void {
        dismissKeyboard()
        if viewModel.needAsk2FA() && cached2faCode == nil {
            NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
            self.performSegueWithIdentifier(self.kAsk2FASegue, sender: self)
        } else {
            ActivityIndicatorHelper.showActivityIndicatorAtView(view)
            viewModel.setNewPassword(currentPwdEditor.text!, new_pwd: newPwdEditor.text!, confirm_new_pwd: confirmPwdEditor.text!, tfaCode: self.cached2faCode, complete: { value, error in
                self.cached2faCode = nil
                ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                if let error = error {
                    if error.code == APIErrorCode.UserErrorCode.currentWrong {
                        self.currentPwdEditor.becomeFirstResponder()
                    }
                    else if error.code == APIErrorCode.UserErrorCode.newNotMatch {
                        self.newPwdEditor.becomeFirstResponder()
                    }
                    
                    let alertController = error.alertController()
                    alertController.addOKAction()
                    self.presentViewController(alertController, animated: true, completion: nil)
                } else {
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
            });
        }
    }

    // MARK: - Actions
    @IBAction func doneAction(sender: AnyObject) {
        startUpdatePwd()
    }
}


// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension ChangePasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(notification: NSNotification) {
        keyboardHeight = 0;
        updateView();
    }
    
    func keyboardWillShowNotification(notification: NSNotification) {
        let info: NSDictionary = notification.userInfo!
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            keyboardHeight = keyboardSize.height;
            updateView();
        }
    }
}

extension ChangePasswordViewController : TwoFACodeViewControllerDelegate {
    func ConfirmedCode(code: String, pwd : String) {
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
        self.cached2faCode = code
        self.startUpdatePwd()
    }
    
    func Cancel2FA() {
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
    }
}

// MARK: - UITextFieldDelegate
extension ChangePasswordViewController: UITextFieldDelegate {
    func textFieldShouldClear(textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if isInputEmpty() {
            self.navigationItem.rightBarButtonItem = nil;
        }
        else {
            self.navigationItem.rightBarButtonItem = doneButton
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch textField
        {
        case currentPwdEditor:
            newPwdEditor.becomeFirstResponder()
            break;
        case newPwdEditor:
            confirmPwdEditor.becomeFirstResponder()
            break
        default:
            if !isInputEmpty() {
                startUpdatePwd()
            }
            else {
                focusFirstEmpty()
            }
            break
        }
        return true
    }
}
