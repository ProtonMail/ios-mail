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
            make.removeExisting = true
            make.right.equalTo()(self.pmView.mas_left)
            make.bottom.equalTo()(self.pmView.mas_bottom)
            make.top.equalTo()(self.pmView.mas_top)
        }
        

//            checkboxWidth.constant = 0.0
//            
//            label1.mas_updateConstraints { (make) -> Void in
//                make.removeExisting = true
//                make.right.equalTo()(self.starImage.mas_left)
//                make.bottom.equalTo()(self.starImage.mas_bottom)
//                make.top.equalTo()(self.starImage.mas_top)
//            }
//            
//            label2.mas_updateConstraints { (make) -> Void in
//                make.removeExisting = true
//                make.right.equalTo()(self.label1.mas_left)
//                make.bottom.equalTo()(self.label1.mas_bottom)
//                make.top.equalTo()(self.label1.mas_top)
//            }
//            label3.mas_updateConstraints { (make) -> Void in
//                make.removeExisting = true
//                make.right.equalTo()(self.label2.mas_left)
//                make.bottom.equalTo()(self.label2.mas_bottom)
//                make.top.equalTo()(self.label2.mas_top)
//            }
//            label4.mas_updateConstraints { (make) -> Void in
//                make.removeExisting = true
//                make.right.equalTo()(self.label3.mas_left)
//                make.bottom.equalTo()(self.label3.mas_bottom)
//                make.top.equalTo()(self.label3.mas_top)
//            }
//            label5.mas_updateConstraints { (make) -> Void in
//                make.removeExisting = true
//                make.right.equalTo()(self.label4.mas_left)
//                make.bottom.equalTo()(self.label4.mas_bottom)
//                make.top.equalTo()(self.label4.mas_top)
//            }
//            

            
        

    }
    
    func updateLabels (labels: [Label]?) {
        if let labels = labels {
            let lc = labels.count - 1;
            for i in 0 ... 4 {
                switch i {
                case 0:
                    var label : Label? = nil
                    if i <= lc {
                        label = labels[i] as? Label
                    }
                    self.updateLablesDetails(label1, label: label)
                case 1:
                    var label : Label? = nil
                    if i <= lc {
                        label = labels[i] as? Label
                    }
                    //self.updateLables(label2, label: label)
                case 2:
                    var label : Label? = nil
                    if i <= lc {
                        label = labels[i] as? Label
                    }
                    //self.updateLables(label3, label: label)
                case 3:
                    var label : Label? = nil
                    if i <= lc {
                        label = labels[i] as? Label
                    }
                    //self.updateLables(label4, label: label)
                case 4:
                    var label : Label? = nil
                    if i <= lc {
                        label = labels[i] as? Label
                    }
                    //self.updateLables(label5, label: label)
                default:
                    break;
                }
            }
            
            
            //label1.sizeToFit()
            var size = label1.sizeThatFits(CGSizeZero)
            label1.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.top.equalTo()(self.pmView)
                make.left.equalTo()(self.pmView)
                make.height.equalTo()(14)
                make.width.equalTo()(self.labelOne.frame.width)
            }
            
            
            
        }
    }
    
    func updateLablesDetails(labelView: LabelDisplayView, label: Label?) {
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


