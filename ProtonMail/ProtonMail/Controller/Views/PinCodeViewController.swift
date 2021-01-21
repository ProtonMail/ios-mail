//
//  PinCodeViewController.swift
//  ProtonMail - Created on 4/6/16.
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


import Foundation
import UIKit
import PromiseKit

protocol PinCodeViewControllerDelegate: class {
    func Cancel() -> Promise<Void>
    func Next()
}

class PinCodeViewController : UIViewController, BioAuthenticating, AccessibleView {
    var viewModel : PinCodeViewModel!
    weak var delegate : PinCodeViewControllerDelegate?
    
    @IBOutlet weak var pinCodeView: PinCodeView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.pinCodeView.delegate = self
        
        self.setUpView(true)
        self.subscribeToWillEnterForegroundMessage()

        NotificationCenter.default.addObserver(forName:  UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] notification in
            self?.pinCodeView.resetPin()
        }
        generateAccessibilityIdentifiers()
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
                self.decideOnBioAuthentication()
            }
        }
        
        if self.viewModel.getPinFailedRemainingCount() < 4 {
            self.pinCodeView.showAttempError(self.viewModel.getPinFailedError(), low: true)
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent;
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
        
        let alert = UIAlertController(title: nil, message: LocalString._logout_secondary_account_from_manager_account, preferredStyle: .alert)
        alert.addAction(.init(title: LocalString._sign_out, style: .destructive, handler: self.proceedCancel))
        alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func proceedCancel(_ sender: Any? = nil) {
        guard let _delegate = self.delegate else {
            // Pin code settings
            self.navigationController?.popViewController(animated: true)
            return
        }
        // unlock when app launch
        _ = _delegate.Cancel().done {
            let _ = self.navigationController?.popViewController(animated: true)
        }
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
