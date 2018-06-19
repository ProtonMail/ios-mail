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
    
    fileprivate let kSegueToSignInWithNoAnimation = "splash_sign_in_no_segue"
    fileprivate let kSegueToSignIn = "splash_sign_in_segue"
    fileprivate let kSegueToSignUp = "splash_sign_up_segue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userCachedStatus.resetSplashCache()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func signUpAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: kSegueToSignUp, sender: self)
    }
    
    @IBAction func signInAction(_ sender: UIButton) {
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kSegueToSignUp {
            let viewController = segue.destination as! SignUpUserNameViewController
            viewController.viewModel = SignupViewModelImpl()
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent;
    }
}
