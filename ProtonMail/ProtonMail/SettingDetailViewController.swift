//
//  DisplayNameViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class SettingDetailViewController: UIViewController {

    @IBOutlet weak var sectionTitleLabel: UILabel!
    
    @IBOutlet weak var switchView: UIView!
    @IBOutlet weak var switchLabel: UILabel!
    @IBOutlet weak var switcher: UISwitch!
    
    @IBOutlet weak var inputTextGroupView: UIView!
    @IBOutlet weak var inputViewTopDistance: NSLayoutConstraint!
    @IBOutlet weak var inputViewHight: NSLayoutConstraint!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var inputTextField: UITextField!
    
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var notesLabel: UILabel!
    let kAsk2FASegue = "password_to_twofa_code_segue"
    
    private var doneButton: UIBarButtonItem!
    private var viewModel : SettingDetailsViewModel!
    func setViewModel(vm:SettingDetailsViewModel) -> Void
    {
        self.viewModel = vm
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        doneButton = self.editButtonItem()
        doneButton.target = self;
        doneButton.action = #selector(SettingDetailViewController.doneAction(_:))
        doneButton.title = "Done"
        self.navigationItem.title = viewModel.getNavigationTitle()
        sectionTitleLabel.text = viewModel.getSectionTitle()
        
        
        if viewModel.isDisplaySwitch() {
            switchLabel.text = viewModel.getSwitchText()
            switcher.on = viewModel.getSwitchStatus()
            switchView.hidden = false
        }
        else {
            switchView.hidden = true
            inputViewTopDistance.constant = 22
        }
        
        if viewModel.isShowTextView() {
            inputViewHight.constant = 200.0
            inputTextField.hidden = true
            inputTextView.hidden = false
            inputTextView.text = viewModel.getCurrentValue()
        }
        else {
            inputViewHight.constant = 44.0
            inputTextField.hidden = false
            inputTextView.hidden = true
            inputTextField.text = viewModel.getCurrentValue()
            inputTextField.placeholder = viewModel.getPlaceholdText()
        }
        
        if viewModel.isRequireLoginPassword() {
            passwordView.hidden = false
        } else {
            passwordView.hidden = true
        }
        
        switcher.enabled = viewModel.isSwitchEnabled()
        inputTextView.editable = viewModel.isSwitchEnabled()
        
        notesLabel.text = viewModel.getNotes()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func doneAction(sender: AnyObject) {
        startUpdateValue()
    }
    
    @IBAction func swiitchAction(sender: AnyObject) {
        if viewModel.getCurrentValue() == inputTextField.text && viewModel.getSwitchStatus() == self.switcher.on {
            self.navigationItem.rightBarButtonItem = nil;
        }
        else {
            self.navigationItem.rightBarButtonItem = doneButton
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
    
    // MARK: private methods
    private func dismissKeyboard() {
        if viewModel.isShowTextView() {
            if (self.inputTextView != nil) {
                self.inputTextView.resignFirstResponder()
            }
        }
        else {
            if (self.inputTextField != nil) {
                self.inputTextField.resignFirstResponder()
            }
        }
    }
    
    private func focusTextField() -> Void {
        if viewModel.isShowTextView() {
            if (self.inputTextView != nil) {
                self.inputTextView.becomeFirstResponder()
            }
        }
        else {
            if (self.inputTextField != nil) {
                self.inputTextField.becomeFirstResponder()
            }
        }
    }
    
    private func getTextValue () -> String {
        if viewModel.isShowTextView() {
            return inputTextView.text
        }
        else {
            return inputTextField.text!
        }
    }
    
    private func getPasswordValue () -> String {
        return passwordTextField.text ?? ""
    }
    
    var cached2faCode : String?
    private func startUpdateValue () -> Void {
        dismissKeyboard()
        if viewModel.needAsk2FA() && cached2faCode == nil {
            self.performSegueWithIdentifier(self.kAsk2FASegue, sender: self)
        } else {
            ActivityIndicatorHelper.showActivityIndicatorAtView(view)
            viewModel.updateNotification(self.switcher.on, complete: { (value, error) -> Void in
                if let error = error {
                    let alertController = error.alertController()
                    alertController.addOKAction()
                    self.presentViewController(alertController, animated: true, completion: nil)
                } else {
                    self.viewModel.updateValue(self.getTextValue(), password: self.getPasswordValue(), tfaCode: self.cached2faCode, complete: { value, error in
                        self.cached2faCode = nil
                        ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                        if let error = error {
                            let alertController = error.alertController()
                            alertController.addOKAction()
                            self.presentViewController(alertController, animated: true, completion: nil)
                        } else {
                            self.navigationController?.popToRootViewControllerAnimated(true)
                        }
                    });
                }
            })
        }
    }
}

extension SettingDetailViewController : TwoFACodeViewControllerDelegate {
    func ConfirmedCode(code: String, pwd : String) {
        self.cached2faCode = code
        self.startUpdateValue()
    }
    
    func Cancel2FA() {
    }
}

// MARK: - UITextFieldDelegate
extension SettingDetailViewController: UITextFieldDelegate {
    func textFieldShouldClear(textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text! as NSString
        let changedText = text.stringByReplacingCharactersInRange(range, withString: string)
        
        if viewModel.getCurrentValue() == changedText && viewModel.getSwitchStatus() == self.switcher.on {
            self.navigationItem.rightBarButtonItem = nil;
        }
        else {
            self.navigationItem.rightBarButtonItem = doneButton
        }
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        startUpdateValue()
        return true
    }
}


extension SettingDetailViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let ctext = textView.text as NSString
        
        let changedText = ctext.stringByReplacingCharactersInRange(range, withString: text)
        
        if viewModel.getCurrentValue() == changedText {
            self.navigationItem.rightBarButtonItem = nil;
        }
        else {
            self.navigationItem.rightBarButtonItem = doneButton
        }
        return true
    }
}
