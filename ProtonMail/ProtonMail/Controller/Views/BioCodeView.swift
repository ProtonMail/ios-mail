//
//  BioCodeView.swift
//  ProtonMail - Created on 19/09/2019.
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

protocol BioCodeViewDelegate: class {
    func touch_id_action(_ sender: Any)
    func pin_unlock_action(_ sender: Any)
}

class BioCodeView: PMView {
    @IBOutlet weak var pinUnlock: UIButton!
    @IBOutlet weak var touchID: UIButton!
    
    weak var delegate: BioCodeViewDelegate?
    
    @IBAction func touch_id_action(_ sender: Any) {
        self.delegate?.touch_id_action(sender)
    }
    
    @IBAction func pin_unlock_action(_ sender: Any) {
        self.delegate?.pin_unlock_action(sender)
    }

    override func getNibName() -> String {
        return "BioCodeView";
    }
    
    override func setup() {
        super.setup()
        
        pinUnlock.alpha = 0.0
        touchID.alpha = 0.0
        
        pinUnlock.isEnabled = false
        touchID.isEnabled = false
        touchID.layer.cornerRadius = 25
    }
    
    func loginCheck(_ flow: SignInUIFlow) {
        switch flow {
        case .requirePin:
            pinUnlock.alpha = 1.0
            pinUnlock.isEnabled = true
            if userCachedStatus.isTouchIDEnabled {
                touchID.alpha = 1.0
                touchID.isEnabled = true
            }

        case .requireTouchID:
            touchID.alpha = 1.0
            touchID.isEnabled = true

        case .restore:
            break
        }
    }
    
    func showErrorAndQuit(errorMsg : String) {
        self.touchID.alpha = 0.0
        self.pinUnlock.alpha = 0.0
    }
}
