//
//  EmailVerifyViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/1/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import UIKit

class PhoneVerifyViewController: ProtonMailViewController, SignupViewModelDelegate {
    
    @IBOutlet weak var emailTextField: TextInsetTextField!
    @IBOutlet weak var verifyCodeTextField: TextInsetTextField!
    
    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var warningIcon: UIImageView!
    
    @IBOutlet weak var titleTwoLabel: UILabel!
    
    @IBOutlet weak var sendCodeButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var pickerButton: UIButton!
    
    //define
    fileprivate let hidePriority : UILayoutPriority = 1.0;
    fileprivate let showPriority: UILayoutPriority = 750.0;
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var userNameTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var topLeftButton: UIButton!
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var phoneFieldNoteLabel: UILabel!
    
    fileprivate let kSegueToNotificationEmail = "sign_up_pwd_email_segue"
    fileprivate let kSegueToCountryPicker = "phone_verify_to_country_picker_segue"
    
    fileprivate var startVerify : Bool = false
    fileprivate var checkUserStatus : Bool = false
    fileprivate var stopLoading : Bool = false
    var viewModel : SignupViewModel!
    
    fileprivate var doneClicked : Bool = false
    
    fileprivate var timer : Timer!
    
    fileprivate var countryCode : String = "+1"
    
    func configConstraint(_ show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level
        
        userNameTopPaddingConstraint.priority = level
        
        titleTwoLabel.isHidden = show
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Cell phone number", comment: "place holder"), attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        verifyCodeTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Enter Verification Code", comment: "place holder"), attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        
        topLeftButton.setTitle(NSLocalizedString("Back", comment: "top left back button"), for: .normal)
        topTitleLabel.text = NSLocalizedString("Human Verification", comment: "human verification top title")
        titleTwoLabel.text = NSLocalizedString("Enter your cell phone number", comment: "human verification top title")
        phoneFieldNoteLabel.text = NSLocalizedString("We will send a verification code to the cell phone above.", comment: "text field notes")
        continueButton.setTitle(NSLocalizedString("Continue", comment: "Action"), for: .normal)
        
        self.updateCountryCode(1)
        self.updateButtonStatus()
    }
    
    func updateCountryCode(_ code : Int) {
        countryCode = "+\(code)"
        pickerButton.setTitle(self.countryCode, for: UIControlState())
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        NotificationCenter.default.addKeyboardObserver(self)
        self.viewModel.setDelegate(self)
        //register timer
        self.startAutoFetch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
        self.viewModel.setDelegate(nil)
        //unregister timer
        self.stopAutoFetch()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func verificationCodeChanged(_ viewModel: SignupViewModel, code: String!) {
        verifyCodeTextField.text = code
    }
    
    fileprivate func startAutoFetch()
    {
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(PhoneVerifyViewController.countDown), userInfo: nil, repeats: true)
        self.timer.fire()
    }
    fileprivate func stopAutoFetch()
    {
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
    }
    
    func countDown() {
        let count = self.viewModel.getTimerSet()
        UIView.performWithoutAnimation { () -> Void in
            if count != 0 {
                self.sendCodeButton.setTitle(String(format: NSLocalizedString("Retry after %d seconds", comment: "Title"), count), for: UIControlState())
            } else {
                self.sendCodeButton.setTitle(NSLocalizedString("Send Verification Code", comment: "Title"), for: UIControlState())
            }
            self.sendCodeButton.layoutIfNeeded()
        }
        updateButtonStatus()
    }
    
    @IBAction func pickerAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: kSegueToCountryPicker, sender: self)
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kSegueToNotificationEmail {
            let viewController = segue.destination as! SignUpEmailViewController
            viewController.viewModel = self.viewModel
        } else if segue.identifier == kSegueToCountryPicker {
            let popup = segue.destination as! CountryPickerViewController
            popup.delegate = self
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        }
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        stopLoading = true
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sendCodeAction(_ sender: UIButton) {
        let phonenumber = emailTextField.text ?? ""
        let buildPhonenumber = "\(countryCode)\(phonenumber)"
        MBProgressHUD.showAdded(to: view, animated: true)
        viewModel.setCodePhone(buildPhonenumber)
        self.viewModel.sendVerifyCode (.sms) { (isOK, error) -> Void in
            MBProgressHUD.hide(for: self.view, animated: true)
            if !isOK {
                var alert :  UIAlertController!
                var title = NSLocalizedString("Verification code request failed", comment: "Title")
                var message = ""
                if error?.code == 12231 {
                    title = NSLocalizedString("Phone number invalid", comment: "Title")
                    message = NSLocalizedString("Please input a valid cell phone number.", comment: "Description")
                } else {
                    message = error!.localizedDescription
                }
                alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addOKAction()
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: NSLocalizedString("Verification code sent", comment: "Title"), message: NSLocalizedString("Please check your cell phone for the verification code.", comment: "Description"), preferredStyle: .alert)
                alert.addOKAction()
                self.present(alert, animated: true, completion: nil)
            }
            PMLog.D("\(isOK),   \(String(describing: error))")
        }
    }
    
    @IBAction func verifyCodeAction(_ sender: UIButton) {
        dismissKeyboard()
        
        if doneClicked {
            return
        }
        doneClicked = true;
        MBProgressHUD.showAdded(to: view, animated: true)
        dismissKeyboard()
        viewModel.setPhoneVerifyCode(verifyCodeTextField.text!)
        DispatchQueue.main.async(execute: { () -> Void in
            self.viewModel.createNewUser { (isOK, createDone, message, error) -> Void in
                MBProgressHUD.hide(for: self.view, animated: true)
                self.doneClicked = false
                if !message.isEmpty {
                    let title = NSLocalizedString("Create user failed", comment: "Title")
                    var message = NSLocalizedString("Default error, please try again.", comment: "Description")
                    if let error = error {
                        message = error.localizedDescription
                    }
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addOKAction()
                    self.present(alert, animated: true, completion: nil)
                } else {
                    if isOK || createDone {
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.performSegue(withIdentifier: self.kSegueToNotificationEmail, sender: self)
                        })
                    }
                }
            }
        })
    }
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        updateButtonStatus()
        dismissKeyboard()
    }
    func dismissKeyboard() {
        emailTextField.resignFirstResponder()
        verifyCodeTextField.resignFirstResponder()
    }
    
    @IBAction func editEnd(_ sender: UITextField) {

    }
    
    @IBAction func editingChanged(_ sender: AnyObject) {
        updateButtonStatus();
    }
    
    func updateButtonStatus() {
        let emailaddress = (emailTextField.text ?? "").trim()
        //need add timer
        if emailaddress.isEmpty || self.viewModel.getTimerSet() > 0 {
            sendCodeButton.isEnabled = false
        } else {
            sendCodeButton.isEnabled = true
        }
        
        let verifyCode = (verifyCodeTextField.text ?? "").trim()
        if verifyCode.isEmpty {
            continueButton.isEnabled = false
        } else {
            continueButton.isEnabled = true
        }
    }
}

extension PhoneVerifyViewController : CountryPickerViewControllerDelegate {
    
    func dismissed() {
        
    }
    
    func apply(_ country: CountryCode) {
        self.updateCountryCode(country.phone_code)
    }
}

// MARK: - UITextFieldDelegatesf
extension PhoneVerifyViewController : UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        updateButtonStatus()
        dismissKeyboard()
        return true
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension PhoneVerifyViewController : NSNotificationCenterKeyboardObserverProtocol {
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
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            scrollBottomPaddingConstraint.constant = keyboardSize.height;
        }
        self.configConstraint(true)
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}
