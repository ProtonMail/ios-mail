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
        
        
        
    }
    
    internal func setUpView() {
        pinCodeView.updateViewText(viewModel.title(), cancelText: viewModel.cancel())
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