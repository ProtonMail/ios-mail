//
//  MultiLabelDisplayView.swift
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

class MultiLabelDisplayView: PMView {
    
    var labels : [Label]?
    
    @IBOutlet var label1: LabelDisplayView!
    
    
    
    var labelOne: LabelDisplayView!
    
    override func getNibName() -> String {
        return "MultiLabelDisplayView";
    }
    
    override func setup() {
        labelOne = LabelDisplayView()
        self.pmView.addSubview(labelOne)
        
        
        label1.mas_updateConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.right.equalTo()(self.pmView.mas_left)
            let _ = make?.bottom.equalTo()(self.pmView.mas_bottom)
            let _ = make?.top.equalTo()(self.pmView.mas_top)
        }
    }
    
    func updateLablesDetails(_ labelView: LabelDisplayView, label: Label?) {
        if let label = label {
            if label.name.isEmpty || label.color.isEmpty {
                //labelView.hidden = true;
            } else {
                //labelView.hidden = false;
                labelView.labelTitle = label.name
                labelView.LabelTintColor = UIColor(hexString: label.color, alpha: 1.0)
            }
        } else {
            //labelView.hidden = true;
        }

    }
    
    
}


