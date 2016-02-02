//
//  SignUpHumanCheckMenu.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/1/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//


import UIKit

class HumanCheckMenuViewController: UIViewController {
    
    private let kSegueToSignUpPassword = "sign_up_password_segue"
    

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
//        if segue.identifier == kSegueToSignUpPassword {
//            let viewController = segue.destinationViewController as! SignUpPasswordViewController
//            viewController.viewModel = self.viewModel
//        }
    }
    
    @IBAction func backAction(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}
