//
//  TwoFACodeViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/3/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation
import UIKit

protocol TwoFACodeViewControllerDelegate {
    func Cancel()
    func ConfirmedCode(code : String)
}

class TwoFACodeViewController : UIViewController {
    //var viewModel : TwoFACodeViewModel!
    @IBOutlet weak var twoFACodeView: TwoFACodeView!
    var delegate : TwoFACodeViewControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.twoFACodeView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
}


extension TwoFACodeViewController : TwoFACodeViewDelegate {

    func ConfirmedCode(code: String) {
        delegate?.ConfirmedCode(code)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func Cancel() {
        delegate?.Cancel()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
