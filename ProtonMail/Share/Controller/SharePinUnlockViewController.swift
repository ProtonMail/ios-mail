//
//  SharePinUnlockViewController.swift
//  Share - Created on 7/26/17.
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
        if userCachedStatus.isTouchIDEnabled {
            
        }
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
                            self.delegate?.next()
                            self.dismiss(animated: true, completion: { })
                        }
                    } else {
                        let count = self.viewModel.getPinFailedRemainingCount()
                        if count == 11 { //when setup
                            self.pinCodeView.resetPin()
                            self.pinCodeView.showAttempError(self.viewModel.getPinFailedError(), low: false)
                        } else if count < 10 {
                            if count <= 0 {
                                SignInManager.shared.clean()
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
