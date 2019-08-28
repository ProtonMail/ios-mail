//
//  SplashViewController.swift
//  ProtonMail - Created on 12/14/15.
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
import DeviceCheck
import PromiseKit

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
    
    enum TokenError : Error {
        case unsupport
        case empty
        case error
    }
    
    func generateToken() -> Promise<String> {
        if #available(iOS 11.0, *) {
            let currentDevice = DCDevice.current
            if currentDevice.isSupported {
                let deferred = Promise<String>.pending()
                currentDevice.generateToken(completionHandler: { (data, error) in
                    if let tokenData = data {
                        deferred.resolver.fulfill(tokenData.base64EncodedString())
                    } else if let error = error {
                        deferred.resolver.reject(error)
                    } else {
                        deferred.resolver.reject(TokenError.empty)
                    }
                })
                return deferred.promise
            }
        }
        return Promise<String>.init(error: TokenError.unsupport)
    }
    
    @IBAction func signUpAction(_ sender: UIButton) {
        firstly {
            generateToken()
        }.done { (token) in
            self.performSegue(withIdentifier: self.kSegueToSignUp, sender: token)
        }.catch { (error) in
            let alert = LocalString._mobile_signups_are_disabled_pls_later_pm_com.alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func signInAction(_ sender: UIButton) {
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kSegueToSignUp {
            
            let viewController = segue.destination as! SignUpUserNameViewController
             let deviceCheckToken = sender as? String ?? ""
            viewController.viewModel = SignupViewModelImpl(token: deviceCheckToken)
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent;
    }
}
