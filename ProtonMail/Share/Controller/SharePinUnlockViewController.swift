//
//  SharePinUnlockViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/26/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//


import UIKit
import Fabric
import Crashlytics
import LocalAuthentication

protocol SharePinUnlockViewControllerDelegate {
    func Cancel()
    func Next()
    func Failed()
}

class SharePinUnlockViewController : UIViewController {
    
    var viewModel : PinCodeViewModel!
    var delegate : SharePinUnlockViewControllerDelegate?
    
    @IBOutlet weak var pinCodeView: PinCodeView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.pinCodeView.delegate = self
        self.pinCodeView.hideTouchID()
        
        self.setUpView(true)
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
            
        }
    }
    
}

extension SharePinUnlockViewController : PinCodeViewDelegate {
    
    func TouchID() {

    }
    
    func Cancel() {
        self.dismiss(animated: true) { 
            self.delegate?.Cancel()
        }
    }
    
    func Next(_ code : String) {
        if code.isEmpty {
//            let alert = LocalString._pin_code_cant_be_empty.alertController()
//            alert.addOKAction()
//            self.present(alert, animated: true, completion: nil)
        } else {
            let step : PinCodeStep = self.viewModel.setCode(code)
            if step != .done {
                self.setUpView(true)
            } else {
                if self.viewModel.isPinMatched() {
                    self.pinCodeView.hideAttempError(true)
                    self.viewModel.done()
                    self.delegate?.Next()
                    self.dismiss(animated: true, completion: {
                    })
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
