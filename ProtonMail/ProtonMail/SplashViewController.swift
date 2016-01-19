//
//  WelcomeViewController.swift
//
//
//  Created by Yanfeng Zhang on 12/14/15.
//
//


import UIKit

class SplashViewController: UIViewController {
    
    @IBOutlet weak var createAccountButton: UIButton!
    
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if sharedUserDataService.isUserCredentialStored {
            self.performSegueWithIdentifier("splash_sign_in_no_segue", sender: self)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func signUpAction(sender: UIButton) {
        self.performSegueWithIdentifier("splash_sign_up_segue", sender: self)
    }
    
    @IBAction func signInAction(sender: UIButton) {
        self.performSegueWithIdentifier("splash_sign_in_segue", sender: self)
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
}
