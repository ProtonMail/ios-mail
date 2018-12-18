//
//  LabelDisplayView.swift
//  ProtonMail - Created on 9/9/15.
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
class LabelDisplayView: PMView {
    
    @IBOutlet weak var labelText: UILabel!
    
    @IBOutlet weak var halfLabelIcon: UIImageView!
    var boardColor : UIColor!
    
    override func getNibName() -> String {
        return "LabelDisplayView"
    }
    
    override func awakeFromNib() {
        
    }
    
    var LabelTintColor : UIColor? {
        get {
            return boardColor;
        }
        set (color) {
            boardColor = color;
            self.updateLabel(color)
        }
    }
    
    var labelTitle : String? {
        get {
            return labelText.text;
        }
        set (t) {
            if let t = t {
                labelText.layer.borderWidth = 1
                halfLabelIcon.isHidden = true
                labelText.text = "  \(t)  ";
            }
        }
    }
    
    func setIcon(_ color : UIColor?) {
        halfLabelIcon.isHidden = false
        labelText.layer.borderWidth = 0
        labelText.text = "";
    }
        
    override func sizeToFit() {
        labelText.sizeToFit();
        super.sizeToFit();
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let s = super.sizeThatFits(size)
        return  CGSize(width: s.width + 4, height: s.height)
    }
    
    override func setup() {
        labelText.layer.borderWidth = 1
        labelText.layer.cornerRadius = 2
        labelText.font = Fonts.h7.light
    }
    
    fileprivate func updateLabel(_ color : UIColor?) {
        if let color = color {

            labelText.textColor = color
            labelText.layer.borderColor = color.cgColor

        }
    }
}
