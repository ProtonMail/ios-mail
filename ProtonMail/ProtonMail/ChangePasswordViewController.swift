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
        doneButton.action = "doneAction:"
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShowOne:", name: UIKeyboardDidShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object:nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object:nil)
    }

    func updateView() {
        var screenHeight = view.frame.height;
        var offbox = screenHeight - textFieldPoint
        if offbox > keyboardHeight {
            topOffset.constant = 8;
        } else {
            topOffset.constant = offbox - keyboardHeight;
        }
    }
    
    // MARK: - Private methods
    func keyboardWillShowOne(sender: NSNotification) {
        let info: NSDictionary = sender.userInfo!
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            println(keyboardSize)
            keyboardHeight = keyboardSize.height;
            updateView();
        }
    }
    
    func keyboardWillHide(sender: NSNotification) {
        keyboardHeight = 0;
        updateView();
    }
    @IBAction func StartEditing(sender: UITextField) {
        
        var frame = sender.convertRect(sender.frame, toView: self.view)
        textFieldPoint = frame.origin.y + frame.height + 40;
        updateView();
    }
    
    private func isInputEmpty() -> Bool {
        if !currentPwdEditor.text.isEmpty {
            return false;
        }
        if !newPwdEditor.text.isEmpty {
            return false;
        }
        if !confirmPwdEditor.text.isEmpty {
            return false;
        }
        return true;
    }
    
    private func focusFirstEmpty() -> Void {
        if currentPwdEditor.text.isEmpty {
            currentPwdEditor.becomeFirstResponder()
        }
        else if newPwdEditor.text.isEmpty {
            newPwdEditor.becomeFirstResponder()
        }
        else if confirmPwdEditor.text.isEmpty {
            confirmPwdEditor.becomeFirstResponder()
        }
    }
    
    private func startUpdatePwd () -> Void {
        dismissKeyboard()
        ActivityIndicatorHelper.showActivityIndicatorAtView(view)
        viewModel.setNewPassword(currentPwdEditor.text, new_pwd: newPwdEditor.text, confirm_new_pwd: confirmPwdEditor.text, complete: { value, error in
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

    // MARK: - Actions
    @IBAction func doneAction(sender: AnyObject) {
        startUpdatePwd()
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
