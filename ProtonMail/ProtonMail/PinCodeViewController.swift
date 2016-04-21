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
                authenticateUser()
            }
        }
    }
    
    internal func setUpView(reset: Bool) {
        pinCodeView.updateViewText(viewModel.title(), cancelText: viewModel.cancel(), resetPin: reset)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        pinCodeView.updateCorner()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
    
    
    func authenticateUser() {
        let savedEmail = userCachedStatus.touchIDEmail
        // Get the local authentication context.
        let context = LAContext()
        // Declare a NSError variable.
        var error: NSError?
        context.localizedFallbackTitle = ""
        // Set the reason string that will appear on the authentication alert.
        var reasonString = "Login: \(savedEmail)"
        
        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            [context .evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: NSError?) -> Void in
                if success {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.viewModel.done()
                        self.delegate?.Next()
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                }
                else{
                    println(evalPolicyError?.localizedDescription)
                    switch evalPolicyError!.code {
                    case LAError.SystemCancel.rawValue:
                        println("Authentication was cancelled by the system")
                        "Authentication was cancelled by the system".alertToast()
                    case LAError.UserCancel.rawValue:
                        println("Authentication was cancelled by the user")
                    case LAError.UserFallback.rawValue:
                        println("User selected to enter custom password")
                        //self.showPasswordAlert()
                    default:
                        println("Authentication failed")
                        //self.showPasswordAlert()
                        "Authentication failed".alertToast()
                    }
                }
            })]
        }
        else{
            var alertString : String = "";
            // If the security policy cannot be evaluated then show a short message depending on the error.
            switch error!.code{
            case LAError.TouchIDNotEnrolled.rawValue:
                alertString = "TouchID is not enrolled, enable it in the system Settings"
            case LAError.PasscodeNotSet.rawValue:
                alertString = "A passcode has not been set, enable it in the system Settings"
            default:
                // The LAError.TouchIDNotAvailable case.
                alertString = "TouchID not available"
            }
            println(alertString)
            println(error?.localizedDescription)
            alertString.alertToast()
        }
    }
}


extension PinCodeViewController : PinCodeViewDelegate {
    
    func Cancel() {
        delegate?.Cancel()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func Next(code : String) {
        if code.isEmpty {
            var alert = "Pin code can't be empty.".alertController()
            alert.addOKAction()
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            var step : PinCodeStep = self.viewModel.setCode(code)
            if step != .Done {
                self.setUpView(true)
            } else {
                if self.viewModel.isPinMatched() {
                    self.viewModel.done()
                    self.delegate?.Next()
                    self.navigationController?.popViewControllerAnimated(true)
                } else {
                    self.pinCodeView.showError()
//                    var alert = "Pin code doesn't match.".alertController()
//                    alert.addOKAction()
//                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
}