//
//  2FACodeView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/3/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

protocol TwoFACodeViewDelegate {
    func ConfirmedCode(code : String)
    func Cancel()
}

class TwoFACodeView : PMView {
    
    var delegate : TwoFACodeViewDelegate?
    
    override func getNibName() -> String {
        return "TwoFACodeView";
    }
    
    override func setup() {
        
    }
    
    @IBAction func cancelAction(sender: UIButton) {
        delegate?.Cancel()
    }
}

