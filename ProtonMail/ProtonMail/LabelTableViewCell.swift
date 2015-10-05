//
//  LabelTableViewCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class LabelTableViewCell: UITableViewCell {
    var vc : UIViewController!;
    var model : LabelMessageModel!
    var label : Label!

    var selectStatus : Int! = 0
    
    @IBOutlet weak var labelView: TableCellLabelView!
    @IBOutlet weak var selectStatusButton: UIButton!
    
    
    @IBOutlet weak var labelWidth: NSLayoutConstraint!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layoutMargins = UIEdgeInsetsZero;
        self.separatorInset = UIEdgeInsetsZero
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.labelView.updateTextFont(UIFont.robotoLight(size: 20))
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func buttonAction(sender: UIButton) {
        selectStatus = selectStatus + 1;
        if selectStatus > 2 {
            selectStatus = 0;
        }
        
        switch selectStatus {
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
    
    
    func ConfigCell(label : Label!, model : LabelMessageModel, vc : UIViewController) {
        self.vc = vc;
        self.label = label;
        self.model = model;
        let w = labelView.setText(label.name, color: UIColor(hexString: label.color, alpha: 1.0))
        labelWidth.constant = w;
        
       // self.switchView.on = applyed
    }
    
//    @IBAction func switchAction(sender: AnyObject) {
//        let s = sender as! UISwitch
//        let on : Bool = s.on
//        if on == true {
//            let isok = viewModel.applyLabel(self.label.labelID)
//            if !isok {
//                var alert = "A message cannot have more than 5 labels".alertController();
//                alert.addOKAction()
//                vc.presentViewController(alert, animated: true, completion: nil)
//                s.on = false
//            }
//        } else {
//            let isok = viewModel.removeLabel(self.label.labelID)
//            if !isok {
//
//            }
//        }
//        
//    }

}
