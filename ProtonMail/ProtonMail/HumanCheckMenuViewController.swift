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
    
    var viewModel : SignupViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
}
