//
//  PinCodeView.swift
//  ProtonMail - Created on 4/6/16.
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
import AudioToolbox

protocol PinCodeViewDelegate : AnyObject {
    func Cancel()
    func Next(_ code : String)
    func TouchID()
}

class PinCodeView : PMView {
    @IBOutlet var roundButtons: [RoundButton]!
    
    @IBOutlet weak var pinView: UIView!
    @IBOutlet weak var pinDisplayView: UITextField!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var touchIDButton: UIButton!
    
    @IBOutlet weak var attempsLabel: UILabel!
    @IBOutlet weak var whiteLineView: UIView!
    
    weak var delegate : PinCodeViewDelegate?
    
    var pinCode : String = ""

    override func getNibName() -> String {
        return "PinCodeView";
    }
    
    func showTouchID() {
        touchIDButton.isHidden = false
    }
    
    func hideTouchID() {
        touchIDButton.isHidden = true
    }
    
    override func setup() {
        touchIDButton.layer.cornerRadius = 25
        touchIDButton.isHidden = true
        
        if UIDevice.current.biometricType == .faceID {
            touchIDButton.setImage(UIImage(named: "face_id_icon"), for: .normal)
        }
    }
    
    func updateBackButton(_ icon: UIImage) {
        backButton.setImage(icon, for: UIControl.State())
        backButton.setTitle("", for: UIControl.State())
    }
    
    func updateViewText(_ title : String, cancelText : String, resetPin : Bool) {
        titleLabel.text = title
        logoutButton.setTitle(cancelText, for: UIControl.State())
        if resetPin {
            self.resetPin()
        }
    }
    
    func updateTitle(_ title : String) {
        titleLabel.text = title
    }
    
    func updateCorner() {
        logoutButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0);
        logoutButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0);
        logoutButton.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0);
    }
    
    @IBAction func touchIDAction(_ sender: AnyObject) {
        delegate?.TouchID()
    }
    
    func showAttempError(_ error:String, low : Bool) {
        pinDisplayView.textColor = UIColor.red
        whiteLineView.backgroundColor = UIColor.red
        attempsLabel.isHidden = false
        attempsLabel.text = error
        if low {
            attempsLabel.backgroundColor = UIColor.red
            attempsLabel.textColor = UIColor.white
        } else {
            attempsLabel.backgroundColor = UIColor.clear
            attempsLabel.textColor = UIColor.red
        }
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    func hideAttempError(_ hide : Bool) {
        pinDisplayView.textColor = UIColor.lightGray
        whiteLineView.backgroundColor = UIColor.white
        attempsLabel.isHidden = hide
    }
    
    internal func add(_ number : Int) {
        pinCode = pinCode + String(number)
        self.updateCodeDisplay()
    }
    
    internal func remove() {
        if !pinCode.isEmpty {
            let index = pinCode.index(before: pinCode.endIndex)
            pinCode = String(pinCode[..<index])
            self.updateCodeDisplay()
        }
    }
    
    internal func resetPin() {
        pinCode = ""
        self.updateCodeDisplay()
    }
    
    internal func updateCodeDisplay() {
        pinDisplayView.text = pinCode
    }
    
    func showError() {
        attempsLabel.shake(3, offset: 10)
        pinCode = ""
    }
    
    @IBAction func buttonActions(_ sender: UIButton) {
        self.hideAttempError(true)
        let numberClicked = sender.tag
        self.add(numberClicked)
    }
    
    @IBAction func deleteAction(_ sender: UIButton) {
        self.hideAttempError(true)
        self.remove()
    }
    
    @IBAction func logoutAction(_ sender: UIButton) {
        delegate?.Next(pinCode)
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        delegate?.Cancel()
    }
    
    
    @IBAction func goAction(_ sender: UIButton) {
        delegate?.Next(pinCode)
    }
    
    internal func changePinStatus(_ pin : UIView, on : Bool) {
        if on {
            pin.backgroundColor = UIColor.lightGray
            pin.layer.borderWidth = 0.0
        } else {
            pin.backgroundColor = UIColor.clear
            pin.layer.borderWidth = 1.0
        }
        
    }
    
}

class RoundButton: UIButton {
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath.init(ovalIn: rect)
        let sublayer = CAShapeLayer()
        
        sublayer.strokeColor = UIColor.white.cgColor
        sublayer.fillColor = UIColor.clear.cgColor
        sublayer.borderWidth = 1.0
        sublayer.path = path.cgPath
        sublayer.name = "pm_border"
        
        self.layer.sublayers?.first(where: { $0.name == "pm_border" })?.removeFromSuperlayer()
        self.layer.addSublayer(sublayer)
    }
}
