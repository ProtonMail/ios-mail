//
//  SignUpHumanCheckMenu.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/1/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//


import UIKit

class HumanCheckMenuViewController: UIViewController {
    
    private let kSegueToRecaptcha = "check_menu_to_recaptcha_verify_segue"
    private let kSegueToEmailVerify = "check_menu_to_email_verify_segue"
    private let kSegueToPhoneVerify = "check_menu_to_phone_verify_segue"
    
    @IBOutlet weak var recaptchaViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var phoneViewConstraint: NSLayoutConstraint!
    
    private let kButtonHeight : CGFloat = 60.0
    
    var viewModel : SignupViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSignUpFunctions()
    }
    
    internal func setupSignUpFunctions () {
        let directs = viewModel.getDirect()
        if directs.count <= 0 {
            let alert = NSLocalizedString("Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer.").alertController()
            alert.addOKAction()
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            for dir in directs {
                if dir == "recaptcha" {
                    recaptchaViewConstraint.constant = kButtonHeight
                } else if dir == "email" {
                    emailViewConstraint.constant = kButtonHeight
                } else if dir == "sms" {
                    phoneViewConstraint.constant = kButtonHeight
                }
            }
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default;
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kSegueToRecaptcha {
            let viewController = segue.destinationViewController as! RecaptchaViewController
            viewController.viewModel = self.viewModel
        } else if segue.identifier == kSegueToEmailVerify {
            let viewController = segue.destinationViewController as! EmailVerifyViewController
            viewController.viewModel = self.viewModel
        } else if segue.identifier == kSegueToPhoneVerify {
            let viewController = segue.destinationViewController as! PhoneVerifyViewController
            viewController.viewModel = self.viewModel
        }
    }
    
    @IBAction func backAction(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func recaptchaAction(sender: UIButton) {
        self.performSegueWithIdentifier(kSegueToRecaptcha, sender: self)
    }
    
    @IBAction func emailVerifyAction(sender: UIButton) {
        self.performSegueWithIdentifier(kSegueToEmailVerify, sender: self)
    }
    
    @IBAction func phoneVerifyAction(sender: UIButton) {
        self.performSegueWithIdentifier(kSegueToPhoneVerify, sender: self)
    }
    
}
