//
//  PinCodeViewController.swift
//  ProtonMail - Created on 4/6/16.
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


import Foundation

import UIKit

protocol PinCodeViewControllerDelegate: class {
    func Cancel()
    func Next()
}


class PinCodeViewController : UIViewController {
    
    var viewModel : PinCodeViewModel!
    weak var delegate : PinCodeViewControllerDelegate?
    
    @IBOutlet weak var pinCodeView: PinCodeView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.pinCodeView.delegate = self
        
        self.setUpView(true)
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector:#selector(PinCodeViewController.doEnterForeground), name:  UIWindowScene.willEnterForegroundNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector:#selector(PinCodeViewController.doEnterForeground), name:  UIApplication.willEnterForegroundNotification, object: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    internal func setUpView(_ reset: Bool) {
        pinCodeView.updateViewText(viewModel.title(), cancelText: viewModel.cancel(), resetPin: reset)
        pinCodeView.updateBackButton(viewModel.backButtonIcon())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        navigationController?.setNavigationBarHidden(true, animated: true)
        pinCodeView.updateCorner()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.layoutIfNeeded()
        
        if self.viewModel.checkTouchID() {
            if userCachedStatus.isTouchIDEnabled {
                pinCodeView.showTouchID()
                authenticateUser()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent;
    }
    
    @objc func doEnterForeground() {
        if userCachedStatus.isTouchIDEnabled {
            authenticateUser()
        }
    }
    
    func authenticateUser() {
        UnlockManager.shared.biometricAuthentication(afterBioAuthPassed: {
            self.viewModel.done() { shouldPop in
                self.delegate?.Next()
                if shouldPop {
                    let _ = self.navigationController?.popViewController(animated: true)
                }
            }
        })
    }
}


extension PinCodeViewController : PinCodeViewDelegate {
    
    func TouchID() {
        if self.viewModel.checkTouchID() {
            if userCachedStatus.isTouchIDEnabled {
                authenticateUser()
                return
            }
        }
        pinCodeView.hideTouchID()
    }
    
    func Cancel() {
        guard self.viewModel.needsLogoutConfirmation() else {
            self.proceedCancel()
            return
        }
        
        let alert = UIAlertController(title: nil, message: LocalString._logout_confirmation, preferredStyle: .alert)
        alert.addAction(.init(title: LocalString._sign_out, style: .destructive, handler: self.proceedCancel))
        alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func proceedCancel(_ sender: Any? = nil) {
        self.delegate?.Cancel()
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func Next(_ code : String) {
        if code.isEmpty {
            let alert = LocalString._pin_code_cant_be_empty.alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        } else {
            let step : PinCodeStep = self.viewModel.setCode(code)
            if step != .done {
                self.setUpView(true)
            } else {
                self.viewModel.isPinMatched() { matched in
                    if matched {
                        self.pinCodeView.hideAttempError(true)
                        self.viewModel.done() { shouldPop in
                            self.delegate?.Next()
                            if shouldPop {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    } else {
                        let count = self.viewModel.getPinFailedRemainingCount()
                        if count == 11 { //when setup
                            self.pinCodeView.resetPin()
                            self.pinCodeView.showAttempError(self.viewModel.getPinFailedError(), low: false)
                        } else if count < 10 {
                            if count <= 0 {
                                self.proceedCancel()
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
    
}
