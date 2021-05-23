//
//  BioCodeView.swift
//  ProtonMail - Created on 19/09/2019.
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

protocol BioCodeViewDelegate: AnyObject {
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
        
        switch UIDevice.current.biometricType {
        case .faceID:
            self.touchID.setImage(UIImage(named: "face_id_icon"), for: .normal)
            self.touchID.isHidden = false
            
        case .touchID:
            self.touchID.setImage(UIImage(named: "touch_id_icon"), for: .normal)
            self.touchID.isHidden = false
            
        case .none:
            self.touchID.isHidden = true
        }
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
