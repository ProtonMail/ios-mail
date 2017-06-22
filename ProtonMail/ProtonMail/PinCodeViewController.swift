//
//  PinCodeViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/6/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation

import UIKit
import Fabric
import Crashlytics
import LocalAuthentication

protocol PinCodeViewControllerDelegate {
    func Cancel()
    func Next()
}


class PinCodeViewController : UIViewController {
    
    var viewModel : PinCodeViewModel!
    var delegate : PinCodeViewControllerDelegate?
    
    @IBOutlet weak var pinCodeView: PinCodeView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.pinCodeView.delegate = self
        
        self.setUpView(true)
        
        if self.viewModel.checkTouchID() {
            if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
                pinCodeView.showTouchID()
                authenticateUser()
            }
        }
    }
    
    internal func setUpView(_ reset: Bool) {
        pinCodeView.updateViewText(viewModel.title(), cancelText: viewModel.cancel(), resetPin: reset)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.layoutIfNeeded()
        NotificationCenter.default.addObserver(self, selector:#selector(SignInViewController.doEnterForeground), name:  NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        pinCodeView.updateCorner()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent;
    }
    
    func doEnterForeground(){
        if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
            authenticateUser()
        }
    }
    
    func authenticateUser() {
        let savedEmail = userCachedStatus.touchIDEmail
        // Get the local authentication context.
        let context = LAContext()
        // Declare a NSError variable.
        var error: NSError?
        context.localizedFallbackTitle = ""
        // Set the reason string that will appear on the authentication alert.
        let reasonString = "Login: \(savedEmail)"
        
        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: Error?) in
                if success {
                    DispatchQueue.main.async {
                        self.viewModel.done()
                        self.delegate?.Next()
                        let _ = self.navigationController?.popViewController(animated: true)
                    }
                }
                else{
                    DispatchQueue.main.async {
                        
                        PMLog.D("\(String(describing: evalPolicyError?.localizedDescription))")
                        switch evalPolicyError!._code {
                        case LAError.Code.systemCancel.rawValue:
                            PMLog.D("Authentication was cancelled by the system")
                            "Authentication was cancelled by the system".alertToast()
                        case LAError.Code.userCancel.rawValue:
                            PMLog.D("Authentication was cancelled by the user")
                        case LAError.Code.userFallback.rawValue:
                            PMLog.D("User selected to enter custom password")
                        //self.showPasswordAlert()
                        default:
                            PMLog.D("Authentication failed")
                            //self.showPasswordAlert()
                            "Authentication failed".alertToast()
                        }
                        
                    }
                }
            })
        }
        else{
            var alertString : String = "";
            // If the security policy cannot be evaluated then show a short message depending on the error.
            switch error!.code{
            case LAError.Code.touchIDNotEnrolled.rawValue:
                alertString = "TouchID is not enrolled, enable it in the system Settings"
            case LAError.Code.passcodeNotSet.rawValue:
                alertString = "A passcode has not been set, enable it in the system Settings"
            default:
                // The LAError.TouchIDNotAvailable case.
                alertString = "TouchID not available"
            }
            PMLog.D(alertString)
            PMLog.D("\(String(describing: error?.localizedDescription))")
            alertString.alertToast()
        }
    }
}


extension PinCodeViewController : PinCodeViewDelegate {
    
    func TouchID() {
        if self.viewModel.checkTouchID() {
            if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
                authenticateUser()
                return
            }
        }
        pinCodeView.hideTouchID()
    }
    
    func Cancel() {
        delegate?.Cancel()
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func Next(_ code : String) {
        if code.isEmpty {
            let alert = "Pin code can't be empty.".alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        } else {
            let step : PinCodeStep = self.viewModel.setCode(code)
            if step != .done {
                self.setUpView(true)
            } else {
                if self.viewModel.isPinMatched() {
                    self.pinCodeView.hideAttempError(true)
                    self.viewModel.done()
                    self.delegate?.Next()
                    let _ = self.navigationController?.popViewController(animated: true)
                } else {
                    let count = self.viewModel.getPinFailedRemainingCount()
                    if count == 11 { //when setup
                        self.pinCodeView.resetPin()
                        self.pinCodeView.showAttempError(self.viewModel.getPinFailedError(), low: false)
                    } else if count < 10 {
                        if count <= 0 {
                            Cancel()
                        } else {
                            self.pinCodeView.resetPin()
                            self.pinCodeView.showAttempError(self.viewModel.getPinFailedError(), low: count < 4)
                        }
                    }
                    self.pinCodeView.showError()
                }
            }
        }
    }
    
}
