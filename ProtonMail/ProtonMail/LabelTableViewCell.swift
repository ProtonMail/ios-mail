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
        var plusCount = 1;
        if model.totalMessages.count <= 1 || 0 ==  model.originalSelected.count || model.originalSelected.count ==  model.totalMessages.count {
            plusCount = 2;
        }
        
        self.model.status = self.model.status + plusCount;
        if self.model.status > 2 {
            self.model.status = 0;
        }
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
    
    func ConfigCell(label : Label!, model : LabelMessageModel?, vc : UIViewController) {
        self.vc = vc;
        self.label = label;
        self.model = model;
        let w = labelView.setText(label.name, color: UIColor(hexString: label.color, alpha: 1.0))
        labelWidth.constant = w;
        
        self.updateStatusButton()
    }
}
