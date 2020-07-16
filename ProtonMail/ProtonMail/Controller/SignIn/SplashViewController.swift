//
//  SplashViewController.swift
//  ProtonMail - Created on 12/14/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


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
            let signInManager = sharedServices.get(by: SignInManager.self)
            let usersManager = sharedServices.get(by: UsersManager.self)
            let viewController = segue.destination as! SignUpUserNameViewController
             let deviceCheckToken = sender as? String ?? ""
            viewController.viewModel = SignupViewModelImpl(token: deviceCheckToken, usersManager: usersManager , signinManager: signInManager)
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent;
    }
}
