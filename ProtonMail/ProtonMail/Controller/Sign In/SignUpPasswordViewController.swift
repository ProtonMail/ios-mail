//
//  SignUpPasswordViewController.swift
//  ProtonMail - Created on 12/18/15.
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

class SignUpPasswordViewController: UIViewController {
    
    //define
    fileprivate let hidePriority : UILayoutPriority = UILayoutPriority(rawValue: 1.0);
    fileprivate let showPriority: UILayoutPriority = UILayoutPriority(rawValue: 750.0);
    
    @IBOutlet weak var createPasswordButton: UIButton!
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var passwordTopPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var loginPasswordField: TextInsetTextField!
    @IBOutlet weak var confirmLoginPasswordField: TextInsetTextField!
    
    @IBOutlet weak var leftTopItem: UIButton!
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var noteOneLable: UILabel!
    @IBOutlet weak var noteTwoLabel: UILabel!
    
    fileprivate let kSegueToEncryptionSetup = "sign_up_password_to_encryption_segue"
    
    var viewModel : SignupViewModel!
    
    fileprivate var stopLoading : Bool = false
    
    func configConstraint(_ show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level
        
        passwordTopPaddingConstraint.priority = level
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginPasswordField.attributedPlaceholder = NSAttributedString(string: LocalString._signup_choose_password,
                                                                      attributes:[NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#9898a8")])
        confirmLoginPasswordField.attributedPlaceholder = NSAttributedString(string: LocalString._composer_eo_confirm_pwd_placeholder,
                                                                             attributes:[NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#9898a8")])
        
        leftTopItem.setTitle(LocalString._general_back_action, for: .normal)
        topTitleLabel.text = LocalString._signup_set_passwords_title
        noteOneLable.text = LocalString._signup_set_pwd_note_1
        noteTwoLabel.text =  LocalString._signup_set_pwd_note_2
        createPasswordButton.setTitle(LocalString._signup_create_account_action, for: .normal)
        
        self.updateButtonStatus()
        
        self.viewModel.fetchDirect { (directs) -> Void in
            
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        NotificationCenter.default.addKeyboardObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kSegueToEncryptionSetup {
            let viewController = segue.destination as! EncryptionSetupViewController
            viewController.viewModel = self.viewModel
        }
    }

    @IBAction func backAction(_ sender: UIButton) {
        stopLoading = true;
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func createPasswordAction(_ sender: UIButton) {
        dismissKeyboard()
        
        let login_pwd = (loginPasswordField.text ?? "")
        let confirm_login_pwd = (confirmLoginPasswordField.text ?? "")
        
        if !login_pwd.isEmpty && confirm_login_pwd == login_pwd {
            //create user & login
            viewModel.setSinglePassword(login_pwd)
            self.performSegue(withIdentifier: kSegueToEncryptionSetup, sender: self)
        } else {
            let alert = LocalString._signup_pwd_doesnt_match.alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        updateButtonStatus()
        dismissKeyboard()
    }
    
    func dismissKeyboard() {
        loginPasswordField.resignFirstResponder()
        confirmLoginPasswordField.resignFirstResponder()
    }
    
    @IBAction func editingEnd(_ sender: AnyObject) {
    }
    
    @IBAction func editingChange(_ sender: AnyObject) {
        updateButtonStatus();
    }
    
    func updateButtonStatus () {
        let login_pwd = (loginPasswordField.text ?? "")
        let confirm_login_pwd = (confirmLoginPasswordField.text ?? "")
        
        if !login_pwd.isEmpty && !confirm_login_pwd.isEmpty {
            createPasswordButton.isEnabled = true
        } else {
            createPasswordButton.isEnabled = false
        }
    }
}

// MARK: - UITextFieldDelegatesf
extension SignUpPasswordViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        updateButtonStatus()
        if textField == loginPasswordField {
            confirmLoginPasswordField.becomeFirstResponder()
        } else if textField == confirmLoginPasswordField {
            dismissKeyboard()
        }
        return true
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension SignUpPasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        scrollBottomPaddingConstraint.constant = 0.0
        self.configConstraint(false)
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            scrollBottomPaddingConstraint.constant = keyboardSize.height;
        }
        self.configConstraint(true)
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}
