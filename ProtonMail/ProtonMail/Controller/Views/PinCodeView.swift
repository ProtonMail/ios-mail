//
//  PinCodeView.swift
//  ProtonMail - Created on 4/6/16.
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
