//
//  PinCodeViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/6/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import UIKit

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
            if userCachedStatus.isTouchIDEnabled {
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
        NotificationCenter.default.addObserver(self, selector:#selector(PinCodeViewController.doEnterForeground), name:  UIApplication.willEnterForegroundNotification, object: nil)
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
    
    @objc func doEnterForeground() {
        if userCachedStatus.isTouchIDEnabled {
            authenticateUser()
        }
    }
    
    func authenticateUser() {
        UnlockManager.shared.biometricAuthentication(afterBioAuthPassed: {
            self.viewModel.done() { _ in
                self.delegate?.Next()
                let _ = self.navigationController?.popViewController(animated: true)
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
        delegate?.Cancel()
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
                        self.viewModel.done() { _ in
                            self.pinCodeView.hideAttempError(true)
                            self.delegate?.Next()
                            let _ = self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        let count = self.viewModel.getPinFailedRemainingCount()
                        if count == 11 { //when setup
                            self.pinCodeView.resetPin()
                            self.pinCodeView.showAttempError(self.viewModel.getPinFailedError(), low: false)
                        } else if count < 10 {
                            if count <= 0 {
                                self.Cancel()
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
