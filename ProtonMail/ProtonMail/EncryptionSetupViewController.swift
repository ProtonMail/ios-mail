//
//  EncryptionViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/11/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation

class EncryptionSetupViewController: UIViewController {
    
    private let kSegueToSignUpVerification = "encryption_to_verification_segue"
    
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
    
    
    private func updateButtonsStatus() {
        let bit = self.viewModel.getCurrentBit()
        if bit == 2048 {
            
        } else if bit == 4096 {
            
        }
    }
    
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kSegueToSignUpVerification {
            let viewController = segue.destinationViewController as! HumanCheckMenuViewController
            viewController.viewModel = self.viewModel
        }
    }
    
    @IBAction func backAction(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func continueAction(sender: UIButton) {
        self.performSegueWithIdentifier(kSegueToSignUpVerification, sender: self)
    }
    

}
