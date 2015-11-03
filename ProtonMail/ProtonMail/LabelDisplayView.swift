//
//  LabelDisplayView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/9/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

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
                halfLabelIcon.hidden = true
                labelText.text = "  \(t)  ";
            }
        }
    }
    
    func setIcon(color : UIColor?) {
        halfLabelIcon.hidden = false
        labelText.layer.borderWidth = 0
        labelText.text = "";
    }
        
    override func sizeToFit() {
        labelText.sizeToFit();
        super.sizeToFit();
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        var s = super.sizeThatFits(size)
        return  CGSize(width: s.width + 4, height: s.height)
    }
    
    override func setup() {
        labelText.layer.borderWidth = 1
        labelText.layer.cornerRadius = 2
        labelText.font = UIFont.robotoLight(size: 9)
    }
    
    private func updateLabel(color : UIColor?) {
        if let color = color {

            labelText.textColor = color
            labelText.layer.borderColor = color.CGColor

        }
    }
}
