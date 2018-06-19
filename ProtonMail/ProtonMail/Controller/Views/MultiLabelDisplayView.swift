//
//  MultiLabelDisplayView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/9/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

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


