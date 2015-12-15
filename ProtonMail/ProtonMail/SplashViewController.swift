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
        
       // self.performSegueWithIdentifier("splash_sign_in_no_segue", sender: self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
       
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
    }
    
    @IBAction func signInAction(sender: UIButton) {
        self.performSegueWithIdentifier("splash_sign_in_segue", sender: self)
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }
}
