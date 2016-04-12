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

class PinCodeViewController : UIViewController {
    
    var viewModel : PinCodeViewModel!
    
    @IBOutlet weak var pinCodeView: PinCodeView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.pinCodeView.delegate = self
        
        self.setUpView(true)
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
}


extension PinCodeViewController : PinCodeViewDelegate {
    
    func Cancel() {
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
                    self.navigationController?.popViewControllerAnimated(true)
                } else {
                    var alert = "Pin code doesn't match.".alertController()
                    alert.addOKAction()
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
}