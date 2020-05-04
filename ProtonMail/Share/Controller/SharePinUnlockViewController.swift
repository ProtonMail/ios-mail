//
//  SharePinUnlockViewController.swift
//  Share - Created on 7/26/17.
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

protocol SharePinUnlockViewControllerDelegate : AnyObject {
    func cancel()
    func next()
    func failed()
}

class SharePinUnlockViewController : UIViewController, CoordinatedNew {
    typealias coordinatorType = SharePinUnlockCoordinator
    private weak var coordinator: SharePinUnlockCoordinator?
    var viewModel : PinCodeViewModel!
    weak var delegate : SharePinUnlockViewControllerDelegate?
    
    func set(coordinator: SharePinUnlockCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return coordinator
    }

    /// UI
    @IBOutlet weak var pinCodeView: PinCodeView!
    
    ///
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
        pinCodeView.updateCorner()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.layoutIfNeeded()
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
//        if userCachedStatus.isTouchIDEnabled {
//            
//        }
    }
}

extension SharePinUnlockViewController : PinCodeViewDelegate {
    
    func TouchID() {

    }
    
    func Cancel() {
        //TODO:: use the coordinator delegated
        self.dismiss(animated: true) { 
            self.delegate?.cancel()
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
                        self.viewModel.done() { _ in
                            self.dismiss(animated: true, completion: {
                                self.delegate?.next()
                            })
                        }
                    } else {
                        let count = self.viewModel.getPinFailedRemainingCount()
                        if count == 11 { //when setup
                            self.pinCodeView.resetPin()
                            self.pinCodeView.showAttempError(self.viewModel.getPinFailedError(), low: false)
                        } else if count < 10 {
                            if count <= 0 {
                                //TODO:: fix me
//                                SignInManager.shared.clean()
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
