//
//  HumanCheckMenuViewController.swift
//  ProtonMail - Created on 2/1/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit

class HumanCheckMenuViewController: UIViewController {
    
    fileprivate let kSegueToRecaptcha = "check_menu_to_recaptcha_verify_segue"
    fileprivate let kSegueToEmailVerify = "check_menu_to_email_verify_segue"
    fileprivate let kSegueToPhoneVerify = "check_menu_to_phone_verify_segue"
    
    @IBOutlet weak var recaptchaViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var phoneViewConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var topLeftButton: UIButton!
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var topNotesLabel: UILabel!
    @IBOutlet weak var optionsTitleLabel: UILabel!
    
    @IBOutlet weak var captchaButton: UIButton!
    @IBOutlet weak var emailCheckButton: UIButton!
    @IBOutlet weak var phoneCheckButton: UIButton!
    
    fileprivate let kButtonHeight : CGFloat = 60.0
    
    var viewModel : SignupViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topLeftButton.setTitle(LocalString._general_back_action, for: .normal)
        topTitleLabel.text = LocalString._human_verification
        topNotesLabel.text = LocalString._to_prevent_abuse_of_protonmail_we_need_to_verify_that_you_are_human
        optionsTitleLabel.text = LocalString._please_select_one_of_the_following_options
        
        captchaButton.setTitle(LocalString._captcha, for: .normal)
        emailCheckButton.setTitle(LocalString._email_verification, for: .normal)
        phoneCheckButton.setTitle(LocalString._phone_verification, for: .normal)
        
        self.setupSignUpFunctions()
    }
    
    internal func setupSignUpFunctions () {
        let directs = viewModel.getDirect()
        if directs.count <= 0 {
            let alert = LocalString._mobile_signups_are_disabled_pls_later_pm_com.alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        } else {
            for dir in directs {
                if dir == "captcha" {
                    recaptchaViewConstraint.constant = kButtonHeight
                } else if dir == "email" {
                    emailViewConstraint.constant = kButtonHeight
                } else if dir == "sms" {
                    phoneViewConstraint.constant = kButtonHeight
                }
            }
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kSegueToRecaptcha {
            let viewController = segue.destination as! RecaptchaViewController
            viewController.viewModel = self.viewModel
        } else if segue.identifier == kSegueToEmailVerify {
            let viewController = segue.destination as! EmailVerifyViewController
            viewController.viewModel = self.viewModel
        } else if segue.identifier == kSegueToPhoneVerify {
            let viewController = segue.destination as! PhoneVerifyViewController
            viewController.viewModel = self.viewModel
        }
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func recaptchaAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: kSegueToRecaptcha, sender: self)
    }
    
    @IBAction func emailVerifyAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: kSegueToEmailVerify, sender: self)
    }
    
    @IBAction func phoneVerifyAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: kSegueToPhoneVerify, sender: self)
    }
    
}
