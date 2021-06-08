//
//  SettingDetailViewController.swift
//  ProtonMail - Created on 3/17/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit
import MBProgressHUD

class SettingDetailViewController: UIViewController {

    @IBOutlet weak var sectionTitleLabel: UILabel!
    
    @IBOutlet weak var titleLabel2: UILabel!
    
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
    let kToUpgradeAlertSegue = "toUpgradeAlertSegue"
    
    fileprivate var doneButton: UIBarButtonItem!
    fileprivate var viewModel : SettingDetailsViewModel!
    func setViewModel(_ vm:SettingDetailsViewModel) -> Void
    {
        self.viewModel = vm
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIViewController.configureNavigationBar(self)
        
        doneButton = self.editButtonItem
        doneButton.target = self;
        doneButton.action = #selector(SettingDetailViewController.doneAction(_:))
        doneButton.title = LocalString._general_save_action
        
        self.navigationItem.title = viewModel.getNavigationTitle()
        sectionTitleLabel.text = viewModel.getSectionTitle()
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: LocalString._general_back_action,
                                            style: UIBarButtonItem.Style.plain,
                                            target: self,
                                            action: #selector(SettingDetailViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        
        if viewModel.isDisplaySwitch() {
            switchLabel.text = viewModel.getSwitchText()
            switcher.isOn = viewModel.getSwitchStatus()
            switchView.isHidden = false
        }
        else {
            switchView.isHidden = true
            inputViewTopDistance.constant = 22
        }
        titleLabel2.text = viewModel.sectionTitle2
        
        if viewModel.isShowTextView() {
            inputViewHight.constant = 200.0
            inputTextField.isHidden = true
            inputTextView.isHidden = false
            inputTextView.text = viewModel.getCurrentValue()
        } else {
            inputViewHight.constant = 44.0
            inputTextField.isHidden = false
            inputTextView.isHidden = true
            inputTextField.text = viewModel.getCurrentValue()
            inputTextField.placeholder = viewModel.getPlaceholdText()
        }
        
        passwordTextField.placeholder = LocalString._login_password
        
        if viewModel.isRequireLoginPassword() {
            passwordView.isHidden = false
        } else {
            passwordView.isHidden = true
        }
        
        switcher.isEnabled = viewModel.isSwitchEnabled()
        inputTextView.isEditable = viewModel.isSwitchEnabled()
        
        notesLabel.text = viewModel.getNotes()
        
        
        //check Role if need a paid feature
        if !viewModel.isSwitchEnabled() {
            self.performSegue(withIdentifier: self.kToUpgradeAlertSegue, sender: self)
        }
    }
    
    @objc func back(sender: UIBarButtonItem) {
        dismissKeyboard()
        if viewModel.getCurrentValue() == getTextValue() && viewModel.getSwitchStatus() == self.switcher.isOn {
            _ = self.navigationController?.popViewController(animated: true)
        }
        else {
            let alertController = UIAlertController(
                title: LocalString._general_confirmation_title,
                message: LocalString._you_have_unsaved_changes_do_you_want_to_save_it,
                preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .destructive, handler: { action in
                _ = self.navigationController?.popViewController(animated: true)
            }))
            
            alertController.addAction(UIAlertAction(title: LocalString._save_changes, style: .default, handler: { action in
                self.startUpdateValue()
            }))
            
            self.present(alertController, animated: true, completion: nil)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func doneAction(_ sender: AnyObject) {
        startUpdateValue()
    }
    
    @IBAction func swiitchAction(_ sender: AnyObject) {
        if viewModel.getCurrentValue() == inputTextField.text && viewModel.getSwitchStatus() == self.switcher.isOn {
            self.navigationItem.rightBarButtonItem = nil;
        }
        else {
            self.navigationItem.rightBarButtonItem = doneButton
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.kAsk2FASegue {
            let popup = segue.destination as! TwoFACodeViewController
            popup.delegate = self
            popup.mode = .twoFactorCode
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        } else if segue.identifier == self.kToUpgradeAlertSegue {
            let popup = segue.destination as! UpgradeAlertViewController
            popup.delegate = self
            sharedVMService.upgradeAlert(signature: popup)
        }
    }
    
    internal func setPresentationStyleForSelfController(_ selfController : UIViewController,  presentingController: UIViewController)
    {
        presentingController.providesPresentationContextTransitionStyle = true;
        presentingController.definesPresentationContext = true;
        presentingController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    }
    
    // MARK: private methods
    fileprivate func dismissKeyboard() {
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
    
    fileprivate func focusTextField() -> Void {
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
    
    fileprivate func getTextValue () -> String {
        if viewModel.isShowTextView() {
            return inputTextView.text
        }
        else {
            return inputTextField.text!
        }
    }
    
    fileprivate func getPasswordValue () -> String {
        return passwordTextField.text ?? ""
    }
    
    var cached2faCode : String?
    fileprivate func startUpdateValue () -> Void {
        dismissKeyboard()
        if viewModel.needAsk2FA() && cached2faCode == nil {
            self.performSegue(withIdentifier: self.kAsk2FASegue, sender: self)
        } else {
            MBProgressHUD.showAdded(to: view, animated: true)
            self.viewModel.updateValue(self.getTextValue(),
                                       password: self.getPasswordValue(),
                                       tfaCode: self.cached2faCode,
                                       complete: { value, error in
                self.cached2faCode = nil
                if let error = error {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let alertController = error.alertController()
                    alertController.addOKAction()
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    self.viewModel.updateNotification(self.switcher.isOn, complete: { (value, error) -> Void in
                        if let error = error {
                            MBProgressHUD.hide(for: self.view, animated: true)
                            let alertController = error.alertController()
                            alertController.addOKAction()
                            self.present(alertController, animated: true, completion: nil)
                        } else {
                            let _ = self.navigationController?.popViewController(animated: true)
                        }
                    })
                }
            })
        }
    }
}

extension SettingDetailViewController : TwoFACodeViewControllerDelegate {
    func ConfirmedCode(_ code: String, pwd : String) {
        self.cached2faCode = code
        self.startUpdateValue()
    }
    
    func Cancel2FA() {
    }
}

extension SettingDetailViewController : UpgradeAlertVCDelegate {
    func goPlans() {
        ///TODO::fixme consider to remove the pop
        self.navigationController?.popViewController(animated: true)
        NotificationCenter.default.post(name: .switchView,
                                        object: DeepLink(MenuCoordinatorNew.Destination.plan.rawValue))
    }
    
    func learnMore() {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(.paidPlans, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(.paidPlans)
        }
    }
    
    func cancel() {
    }
    
}

// MARK: - UITextFieldDelegate
extension SettingDetailViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text! as NSString
        let changedText = text.replacingCharacters(in: range, with: string)
        
        if viewModel.getCurrentValue() == changedText && viewModel.getSwitchStatus() == self.switcher.isOn {
            self.navigationItem.rightBarButtonItem = nil;
        }
        else {
            self.navigationItem.rightBarButtonItem = doneButton
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        startUpdateValue()
        return true
    }
}


extension SettingDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let ctext = textView.text as NSString
        
        let changedText = ctext.replacingCharacters(in: range, with: text)
        
        if viewModel.getCurrentValue() == changedText {
            self.navigationItem.rightBarButtonItem = nil;
        }
        else {
            self.navigationItem.rightBarButtonItem = doneButton
        }
        return true
    }
}
