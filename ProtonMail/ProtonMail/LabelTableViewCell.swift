//
//  LabelTableViewCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class LabelTableViewCell: UITableViewCell {
    var vc : UIViewController!
    var model : LabelMessageModel!
    let maxLabelCount : Int = 100

    @IBOutlet weak var labelView: TableCellLabelView!
    @IBOutlet weak var selectStatusButton: UIButton!
    
    @IBOutlet weak var labelWidth: NSLayoutConstraint!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layoutMargins = UIEdgeInsetsZero;
        self.separatorInset = UIEdgeInsetsZero
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.labelView.updateTextFont(UIFont.robotoLight(size: 20))
        selectStatusButton.enabled = false
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func buttonAction(sender: UIButton) {
        self.selectAction()
    }
    
    func uncheckAction() {
        if self.model.status == 2 {
            selectAction()
        } else {
            self.updateStatusButton()
        }
    }
    
    func selectAction() {
        var plusCount = 1
        if model.totalMessages.count <= 1 || 0 ==  model.originalSelected.count || model.originalSelected.count ==  model.totalMessages.count {
            plusCount = 2
        }
        
        var tempStatus = self.model.status + plusCount;
        if tempStatus > 2 {
            tempStatus = 0
        }
        
        if tempStatus == 0 {
            for mm in self.model.totalMessages {
                let labelObjs = mm.mutableSetValueForKey("labels")
                labelObjs.removeObject(model.label)
                mm.setValue(labelObjs, forKey: "labels")
            }
        } else if tempStatus == 1 {
            for mm in self.model.totalMessages {
                let labelObjs = mm.mutableSetValueForKey("labels")
                labelObjs.removeObject(model.label)
                mm.setValue(labelObjs, forKey: "labels")
            }
            
            for mm in self.model.originalSelected {
                let labelObjs = mm.mutableSetValueForKey("labels")
                labelObjs.addObject(model.label)
                mm.setValue(labelObjs, forKey: "labels")
            }
        } else if tempStatus == 2 {
            for mm in self.model.totalMessages {
                let labelObjs = mm.mutableSetValueForKey("labels")
                var labelCount = 0
                for l in labelObjs {
                    if (l as! Label).labelID != model.label.labelID {
                        labelCount += 1
                    }
                }
                if labelCount >= maxLabelCount {
                    let alert = NSLocalizedString("A message cannot have more than \(maxLabelCount) labels").alertController();
                    alert.addOKAction()
                    vc.presentViewController(alert, animated: true, completion: nil)
                    return;
                }
            }
            
            for mm in self.model.totalMessages {
                let labelObjs = mm.mutableSetValueForKey("labels")
                labelObjs.addObject(model.label)
                mm.setValue(labelObjs, forKey: "labels")
            }
        }
        
        self.model.status = tempStatus
        self.updateStatusButton();
    }

    func updateStatusButton () {
        switch self.model.status {
        case 0:
            selectStatusButton.setImage(UIImage(named:"mail_check"), forState: UIControlState.Normal)
            break
        case 1:
            selectStatusButton.setImage(UIImage(named:"mail_check-neutral"), forState: UIControlState.Normal)
            break;
        case 2:
            selectStatusButton.setImage(UIImage(named:"mail_check-active"), forState: UIControlState.Normal)
            break
        default:
            selectStatusButton.setImage(UIImage(named:"mail_check"), forState: UIControlState.Normal)
            break
        }
    }
    
    func ConfigCell(model : LabelMessageModel!, uncheck : Bool, vc : UIViewController) {
        self.vc = vc;
        self.model = model;
        if model.label.managedObjectContext != nil {
            let w = labelView.setText(model.label.name, color: UIColor(hexString: model.label.color, alpha: 1.0))
            let check = self.frame.width - 50
            labelWidth.constant = w > check ? check : w
        }
        
        if uncheck {
            self.uncheckAction()
        } else {
            self.updateStatusButton()
        }
        
    }
}
