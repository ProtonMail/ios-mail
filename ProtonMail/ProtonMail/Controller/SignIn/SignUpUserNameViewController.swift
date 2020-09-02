//
//  SignUpUserNameViewController.swift
//  ProtonMail - Created on 12/17/15.
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

class SignUpUserNameViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextViewDelegate {
    
    @IBOutlet weak var usernameTextField: TextInsetTextField!
    @IBOutlet weak var pickedDomainLabel: UILabel!
    
    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var warningIcon: UIImageView!
    
    @IBOutlet weak var agreeCheck: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var pickerButton: UIButton!
    
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var leftBackItem: UIButton!
    
    @IBOutlet weak var userNameNoteLabel: UILabel!
    @IBOutlet weak var agreementButton: UIButton!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var andLable: UILabel!
    @IBOutlet weak var privacyButton: UIButton!
    
    //define
    fileprivate let hidePriority : UILayoutPriority = UILayoutPriority(rawValue: 1.0);
    fileprivate let showPriority: UILayoutPriority = UILayoutPriority(rawValue: 750.0);
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userNameTopPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    
    var domains : [String] = ["protonmail.com", "protonmail.ch"]
    var selected : Int = 0;
    
    fileprivate let kSegueToSignUpPassword = "sign_up_password_segue"
    
    fileprivate let kToTerms = "sign_up_username_to_terms"
    fileprivate let kToPolicy = "sign_up_username_to_policy"
    
    fileprivate var startVerify : Bool = false
    fileprivate var checkUserStatus : Bool = false
    fileprivate var stopLoading : Bool = false
    fileprivate var agreePolicy : Bool = true
    fileprivate var moveAfterCheck : Bool = false
    
    var viewModel : SignupViewModel!
    
    func configConstraint(_ show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level
        
        userNameTopPaddingConstraint.priority = level
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetChecking()
        self.viewModel.observeTextField(textField: usernameTextField, type: .username)
        usernameTextField.attributedPlaceholder = NSAttributedString(string: LocalString._username,
                                                                     attributes:[NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#9898a8")])
        MBProgressHUD.showAdded(to: view, animated: true)
        pickerButton.isHidden = true
        pickedDomainLabel.isHidden = true
        viewModel.getDomains { (ds : [String]) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.pickerButton.isHidden = false
            self.pickedDomainLabel.isHidden = false
            self.domains = ds
            self.updatePickedDomain()
        }
        leftBackItem.setTitle(LocalString._general_back_action, for: .normal)
        topTitleLabel.text = LocalString._create_a_new_account
        userNameNoteLabel.text = LocalString._notes_the_username_is_also_your_protonmail_address
        agreementButton.setTitle(LocalString._notes_by_using_protonmail_you_agree_to_our, for: .normal)
        termsButton.setTitle(LocalString._notes_terms_and_conditions, for: .normal)
        andLable.text = LocalString._and
        privacyButton.setTitle(LocalString._privacy_policy, for: .normal)
        createAccountButton.setTitle(LocalString._signup_create_account_action, for: .normal)
        
        self.updatePickedDomain()
    }
    
    func updatePickedDomain () {
        pickedDomainLabel.text = "@\(domains[selected])"
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default;
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
        if segue.identifier == kSegueToSignUpPassword {
            let viewController = segue.destination as! SignUpPasswordViewController
            viewController.viewModel = self.viewModel
        } else if segue.identifier == self.kToTerms {
            let viewController = segue.destination as! WebViewController
            sharedVMService.buildTerms(viewController)
        } else if segue.identifier == self.kToPolicy {
            let viewController = segue.destination as! WebViewController
            sharedVMService.buildPolicy(viewController)
        }
    }
    @IBAction func checkAction(_ sender: AnyObject) {
        dismissKeyboard()
        agreeCheck.isSelected = !agreeCheck.isSelected
        agreePolicy = agreeCheck.isSelected
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        stopLoading = true
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func startChecking() {
        warningView.isHidden = false
        warningLabel.textColor = UIColor(hexString: "A2C173", alpha: 1.0)
        warningLabel.text = LocalString._checking_
        warningIcon.isHidden = true;
    }
    
    func resetChecking() {
        checkUserStatus = false
        warningView.isHidden = true
        warningLabel.textColor = UIColor(hexString: "A2C173", alpha: 1.0)
        warningLabel.text = ""
        warningIcon.isHidden = true
    }
    
    func finishChecking(_ status : CheckUserExistResponse.AvailabilityStatus) {
        guard case CheckUserExistResponse.AvailabilityStatus.available = status else {
            warningView.isHidden = false
            warningLabel.textColor = UIColor.red
            warningLabel.text = status.description
            warningIcon.isHidden = true
            return
        }
        
        checkUserStatus = true
        warningView.isHidden = false
        warningLabel.textColor = UIColor(hexString: "A2C173", alpha: 1.0)
        warningLabel.text = status.description
        warningIcon.isHidden = false
    }
    
    @IBAction func createAccountAction(_ sender: UIButton) {
        dismissKeyboard()
        MBProgressHUD.showAdded(to: view, animated: true)
        if agreePolicy {
            if checkUserStatus {
                MBProgressHUD.hide(for: view, animated: true)
                self.goPasswordsView()
            } else {
                let userName = (usernameTextField.text ?? "").trim()
                if !userName.isEmpty {
                    startChecking()
                    viewModel.checkUserName(userName, complete: { result in
                        MBProgressHUD.hide(for: self.view, animated: true)
                        switch result {
                        case .fulfilled(let status):
                            self.finishChecking(status)
                            if case CheckUserExistResponse.AvailabilityStatus.available = status {
                                self.goPasswordsView()
                            }
                        case .rejected(let error):
                            let alert = error.localizedDescription.alertController()
                            alert.addOKAction()
                            self.present(alert, animated: true, completion: nil)
                            self.resetChecking()
                        }
                    })
                } else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let alert = LocalString._please_pick_a_user_name_first.alertController()
                    alert.addOKAction()
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            MBProgressHUD.hide(for: view, animated: true)
            let alert = LocalString._in_order_to_use_our_services_you_must_agree_to_protonmails_terms_of_service.alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func goPasswordsView() {
        let username = (usernameTextField.text ?? "").trim()
        viewModel.setPickedUserName(username, domain: domains[selected])
        self.performSegue(withIdentifier: kSegueToSignUpPassword, sender: self)
    }
    
    @IBAction func pickDomainName(_ sender: UIButton) {
        showPickerInActionSheet(sender)
    }
    
    func showPickerInActionSheet(_ sender : UIButton) {
        let title = ""
        let message = "\n\n\n\n\n\n\n\n\n\n";
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.actionSheet);
        alert.isModalInPopover = true;
        
        //Create a frame (placeholder/wrapper) for the picker and then create the picker
        let pickerFrame: CGRect = CGRect(x: 17, y: 52, width: 270, height: 100); // CGRectMake(left), top, width, height) - left and top are like margins
        let picker: UIPickerView = UIPickerView(frame: pickerFrame);
        
        //set the pickers datasource and delegate
        picker.delegate = self;
        picker.dataSource = self;
        
        //Add the picker to the alert controller
        alert.view.addSubview(picker);
        
        //Create the toolbar view - the view witch will hold our 2 buttons
        let toolFrame = CGRect(x: 17, y: 5, width: 270, height: 45);
        let toolView: UIView = UIView(frame: toolFrame);
        
        //add buttons to the view
        let buttonCancelFrame: CGRect = CGRect(x: 0, y: 7, width: 100, height: 30); //size & position of the button as placed on the toolView
        
        //Create the cancel button & set its title
        let buttonCancel: UIButton = UIButton(frame: buttonCancelFrame);
        buttonCancel.setTitle(LocalString._general_done_button, for: UIControl.State());
        
        buttonCancel.setTitleColor(UIColor.blue, for: UIControl.State());
        toolView.addSubview(buttonCancel); //add it to the toolView
        
        //Add the target - target, function to call, the event witch will trigger the function call
        buttonCancel.addTarget(self, action: #selector(SignUpUserNameViewController.cancelSelection(_:)), for: UIControl.Event.touchDown);
        
        //add the toolbar to the alert controller
        alert.view.addSubview(toolView);
        
        picker.selectRow(selected, inComponent: 0, animated: true)
        alert.popoverPresentationController?.sourceView = sender
        alert.popoverPresentationController?.sourceRect = sender.bounds
        self.present(alert, animated: true, completion: nil);
    }
    
    func pickedOK(_ sender: UIButton){
        PMLog.D("OK");
        self.dismiss(animated: true, completion: nil);
    }
    
    @objc func cancelSelection(_ sender: UIButton){
        PMLog.D("Cancel");
        self.dismiss(animated: true, completion: nil);
    }
    
    // Return the title of each row in your picker ... In my case that will be the profile name or the username string
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return domains[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selected = row;
        updatePickedDomain ()
    }
    
    // returns the number of 'columns' to display.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return domains.count
    }
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    func dismissKeyboard() {
        usernameTextField.resignFirstResponder()
    }
    
    @IBAction func editEnd(_ sender: UITextField) {
        checkUserName();
    }
    
    func checkUserName() {
        let userName = (usernameTextField.text ?? "").trim()
        guard !stopLoading && !checkUserStatus && !userName.isEmpty else {
            return
        }
        startChecking()
        viewModel.checkUserName(userName, complete: { (response) -> Void in
            switch response {
            case .fulfilled(let status):
                self.finishChecking(status)
            case .rejected(let error):
                let alert = error.localizedDescription.alertController()
                alert.addOKAction()
                self.present(alert, animated: true, completion: nil)
                self.resetChecking()
            }
        })
    }
    
    func updateCreateButton() {
        
    }
    
    @IBAction func editingChanged(_ sender: AnyObject) {
        resetChecking()
    }
    
    @IBAction func termsAction(_ sender: UIButton) {
        dismissKeyboard()
        self.performSegue(withIdentifier: kToTerms, sender: nil)
    }
    
    @IBAction func policyAction(_ sender: UIButton) {
        dismissKeyboard()
        self.performSegue(withIdentifier: kToPolicy, sender: nil)
    }
}

// MARK: - UITextFieldDelegatesf
extension SignUpUserNameViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension SignUpUserNameViewController: NSNotificationCenterKeyboardObserverProtocol {
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


extension CheckUserExistResponse.AvailabilityStatus: CustomStringConvertible {
    var description: String {
        switch self {
        case .available: return LocalString._user_is_available
        case .invalidCharacters(let reason): return reason
        case .startWithSpecialCharacterForbidden(let reason): return reason
        case .endWithSpecialCharacterForbidden(let reason): return reason
        case .tooLong(let reason): return reason
        case .unavailable(let reason, _): return reason
        case .other(let reason): return reason
        }
    }
}
