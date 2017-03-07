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
    @IBOutlet weak var labelIcon: UIImageView!
    @IBOutlet weak var labelleft: NSLayoutConstraint!
    @IBOutlet weak var labelWidth: NSLayoutConstraint!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layoutMargins = UIEdgeInsets.zero;
        self.separatorInset = UIEdgeInsets.zero
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.labelView.updateTextFont(UIFont.robotoLight(size: 20))
        selectStatusButton.isEnabled = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func buttonAction(_ sender: UIButton) {

    }
    
    func updateStatusButton () {
        switch self.model.currentStatus {
        case 0:
            selectStatusButton.setImage(UIImage(named:"mail_check"), for: UIControlState())
            break
        case 1:
            selectStatusButton.setImage(UIImage(named:"mail_check-neutral"), for: UIControlState())
            break;
        case 2:
            selectStatusButton.setImage(UIImage(named:"mail_check-active"), for: UIControlState())
            break
        default:
            selectStatusButton.setImage(UIImage(named:"mail_check"), for: UIControlState())
            break
        }
    }
    
    func ConfigCell(model : LabelMessageModel!, showIcon : Bool, vc : UIViewController) {
        self.vc = vc;
        self.model = model;
        if model.label.managedObjectContext != nil {
            let w = labelView.setText(model.label.name, color: UIColor(hexString: model.label.color, alpha: 1.0))
            let check = self.frame.width - 50
            labelWidth.constant = w > check ? check : w
            
            if showIcon {
                labelIcon.isHidden = false
                labelleft.priority = 500
                let color = UIColor(hexString: model.label.color, alpha:1)
                var image = UIImage(named: "menu_label")
                if model.label.exclusive {
                    image = UIImage(named: "menu_folder")
                }
                
                labelIcon.image = image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                labelIcon.highlightedImage = image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                labelIcon.tintColor = color
            } else {
                labelIcon.isHidden = true
                labelleft.priority = 900
            }
        }
        self.updateStatusButton()
    }
}
