//
//  DisplayNameViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class SettingDetailViewController: UIViewController {

    @IBOutlet weak var topHelpImage: UIButton!
    @IBOutlet weak var topHelpLabel: UILabel!
    
    @IBOutlet weak var sectionTitleLabel: UILabel!
    
    @IBOutlet weak var switchView: UIView!
    @IBOutlet weak var switchLabel: UILabel!
    @IBOutlet weak var switcher: UISwitch!
    
    @IBOutlet weak var inputTextGroupView: UIView!
    @IBOutlet weak var inputViewTopDistance: NSLayoutConstraint!
    @IBOutlet weak var inputViewHight: NSLayoutConstraint!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var inputTextField: UITextField!
    
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
        doneButton.action = "doneAction:"
        doneButton.title = "Done"
        self.navigationItem.title = viewModel.getNavigationTitle()
        topHelpLabel.text = viewModel.getTopHelpText()
        sectionTitleLabel.text = viewModel.getSectionTitle()
        
        
        if viewModel.isDisplaySwitch() {
            switchLabel.text = viewModel.getSwitchText()
            switcher.on = viewModel.getSwitchStatus()
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func doneAction(sender: AnyObject) {
        startUpdateValue()
    }
    
    @IBAction func swiitchAction(sender: AnyObject) {

        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.inputTextGroupView.alpha = self.switcher.on ? 1.0 : 0
            self.inputTextField.text = ""
        })
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
            return inputTextField.text
        }
    }
    
    private func startUpdateValue () -> Void {
        dismissKeyboard()
        ActivityIndicatorHelper.showActivityIndicatorAtView(view)
        viewModel.updateValue(getTextValue(), complete: { value, error in
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
}

// MARK: - UITextFieldDelegate
extension SettingDetailViewController: UITextFieldDelegate {
    func textFieldShouldClear(textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text as NSString
        let changedText = text.stringByReplacingCharactersInRange(range, withString: string)
        
        if viewModel.getCurrentValue() == changedText {
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
