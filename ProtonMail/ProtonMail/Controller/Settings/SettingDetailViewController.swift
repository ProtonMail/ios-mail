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
import ProtonCore_Networking
import ProtonCore_UIFoundations
import ProtonCore_PaymentsUI

class SettingDetailViewController: UIViewController {
    
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
    
    @IBOutlet weak var textFiledSectionTitle: UILabel!

    @IBOutlet weak var notesLabel: UILabel!
    private let kAsk2FASegue = "password_to_twofa_code_segue"
    
    fileprivate var doneButton: UIBarButtonItem!
    fileprivate var viewModel : SettingDetailsViewModel!
    private var paymentsUI: PaymentsUI?
    func setViewModel(_ vm:SettingDetailsViewModel) -> Void
    {
        self.viewModel = vm
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = ColorProvider.BackgroundSecondary
        UIViewController.configureNavigationBar(self)

        switchView.backgroundColor = ColorProvider.BackgroundNorm
        
        doneButton = self.editButtonItem
        doneButton.target = self;
        doneButton.action = #selector(SettingDetailViewController.doneAction(_:))
        doneButton.title = LocalString._general_save_action
        var attribute = FontManager.DefaultStrong
        attribute[.foregroundColor] = ColorProvider.InteractionNorm
        doneButton.setTitleTextAttributes(attribute, for: .normal)
        attribute[.foregroundColor] = ColorProvider.InteractionNormDisabled
        doneButton.setTitleTextAttributes(attribute, for: .disabled)
        doneButton.isEnabled = false

        self.navigationItem.rightBarButtonItem = doneButton

        switcher.onTintColor = ColorProvider.BrandNorm

        inputTextField.font = .systemFont(ofSize: 17.0)
        inputTextField.textColor = ColorProvider.TextNorm
        inputTextField.backgroundColor = ColorProvider.BackgroundNorm

        inputTextView.backgroundColor = ColorProvider.BackgroundNorm

        inputTextGroupView.backgroundColor = ColorProvider.BackgroundNorm
        
        self.navigationItem.title = viewModel.getNavigationTitle()
        
        self.navigationItem.hidesBackButton = true

        self.navigationItem.leftBarButtonItem = UIBarButtonItem.backBarButtonItem(target: self, action: #selector(back(sender:)))
        
        if viewModel.isDisplaySwitch() {
            switchLabel.attributedText = NSAttributedString(string: viewModel.getSwitchText(), attributes: FontManager.Default)
            switcher.isOn = viewModel.getSwitchStatus()
            switchView.isHidden = false
        }
        else {
            switchView.isHidden = true
            inputViewTopDistance.constant = 42
        }
        
        if viewModel.isShowTextView() {
            inputViewHight.constant = 200.0
            inputTextField.isHidden = true
            inputTextView.isHidden = false
            inputTextView.text = viewModel.getCurrentValue()
            if viewModel.getCurrentValue().isEmpty {
                inputTextView.text = viewModel.getPlaceholdText()
                inputTextView.textColor = ColorProvider.TextHint
            }
        } else {
            inputViewHight.constant = 48.0
            inputTextField.isHidden = false
            inputTextView.isHidden = true
            inputTextField.text = viewModel.getCurrentValue()
            inputTextField.placeholder = viewModel.getPlaceholdText()
        }

        if !viewModel.sectionTitle2.isEmpty {
            textFiledSectionTitle.attributedText = viewModel.sectionTitle2.apply(style: FontManager.DefaultSmallWeak)
        } else if !switchView.isHidden {
            textFiledSectionTitle.isHidden = true
            inputViewTopDistance.constant = inputViewTopDistance.constant - 28.0
        } else {
            textFiledSectionTitle.isHidden = true
        }

        passwordTextField.placeholder = LocalString._signin_password

        passwordView.isHidden = true
        
        switcher.isEnabled = viewModel.isSwitchEnabled()
        inputTextView.isEditable = viewModel.isSwitchEnabled()
        
        notesLabel.text = viewModel.getNotes()
        
        
        //check Role if need a paid feature
        if !viewModel.isSwitchEnabled() {
            presentPlanUpgrade()
        }
    }
    
    @objc func back(sender: UIBarButtonItem) {
        dismissKeyboard()
        if (viewModel.getCurrentValue() == getTextValue() || viewModel.getPlaceholdText() == getTextValue()) && viewModel.getSwitchStatus() == self.switcher.isOn {
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
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        else {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.kAsk2FASegue {
            let popup = segue.destination as! TwoFACodeViewController
            popup.delegate = self
            popup.mode = .twoFactorCode
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        }
    }
    
    internal func setPresentationStyleForSelfController(_ selfController : UIViewController,  presentingController: UIViewController)
    {
        presentingController.providesPresentationContextTransitionStyle = true;
        presentingController.definesPresentationContext = true;
        presentingController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    }
    
    // MARK: private methods

    private func presentPlanUpgrade() {
        self.paymentsUI = PaymentsUI(payments: self.viewModel.userManager.payments, clientApp: .mail, shownPlanNames: Constants.shownPlanNames)
        self.paymentsUI?.showUpgradePlan(presentationType: .modal,
                                         backendFetch: true,
                                         updateCredits: false) { _ in }
    }

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
            guard inputTextView.textColor != ColorProvider.TextHint else {
                return ""
            }
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
        } else if viewModel.isRequireLoginPassword() {
            let alert = UIAlertController(title: LocalString._settings_detail_re_auth_alert_title,
                                          message: LocalString._settings_detail_re_auth_alert_content,
                                          preferredStyle: .alert)
            alert.addTextField(configurationHandler: { $0.isSecureTextEntry = true })
            alert.addCancelAction()
            let enterAction = UIAlertAction(title: "Enter", style: .default) { (_) in
                let pwd = alert.textFields?.first?.text ?? ""
                self.updateValue(password: pwd)
            }
            alert.addAction(enterAction)
            self.present(alert, animated: true, completion: nil)
        } else {
            self.updateValue(password: "")
        }
    }

    private func updateValue(password: String) {
        MBProgressHUD.showAdded(to: view, animated: true)
        self.viewModel.updateValue(self.getTextValue(),
                                   password: password,
                                   tfaCode: self.cached2faCode,
                                   complete: { value, error in
            self.cached2faCode = nil
            if let error = error {
                self.showErrorAlert(error)
            } else {
                self.viewModel.updateNotification(self.switcher.isOn, complete: { (value, error) -> Void in
                    if let error = error {
                        if error.code == 12021 {
                            self.showErrorOfNoNotificationEmail(error)
                        } else {
                            self.showErrorAlert(error)
                        }
                    } else {
                        let _ = self.navigationController?.popViewController(animated: true)
                    }
                })
            }
        })
    }

    private func showErrorAlert(_ error: NSError) {
        MBProgressHUD.hide(for: self.view, animated: true)
        if let responseError = error as? ResponseError,
           let underlyingError = responseError.underlyingError {
            underlyingError.alertToast()
        } else {
            error.alertToast()
        }
    }

    private func showErrorOfNoNotificationEmail(_ error: NSError) {
        let err = NSError(domain: error.domain,
                          code: error.code,
                          localizedDescription: LocalString._settings_recovery_email_empty_alert_title,
                          localizedFailureReason: LocalString._settings_recovery_email_empty_alert_content,
                          localizedRecoverySuggestion: error.localizedRecoverySuggestion)
        self.showErrorAlert(err)
    }
}

extension SettingDetailViewController : TwoFACodeViewControllerDelegate {
    func confirmedCode(_ code: String, pwd : String) {
        self.cached2faCode = code
        self.startUpdateValue()
    }
    
    func cancel2FA() {
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
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        else {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        startUpdateValue()
        return true
    }
}


extension SettingDetailViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == ColorProvider.TextHint {
            textView.text = nil
            textView.textColor = ColorProvider.TextNorm
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = viewModel.getPlaceholdText()
            textView.textColor = ColorProvider.TextHint
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let ctext = textView.text as NSString
        
        let changedText = ctext.replacingCharacters(in: range, with: text)
        
        if viewModel.getCurrentValue() == changedText {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        else {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
        return true
    }
}
