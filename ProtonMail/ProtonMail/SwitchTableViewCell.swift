//
//  CustomHeaderView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit


typealias ActionStatus = (_ isOK: Bool) -> Void
typealias switchActionBlock = (_ cell: SwitchTableViewCell?, _ newStatus: Bool, _ feedback: @escaping ActionStatus) -> Void

class SwitchTableViewCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    var callback : switchActionBlock?
    
    @IBOutlet weak var centerConstraint: NSLayoutConstraint!
    @IBOutlet weak var topLineLabel: UILabel!
    @IBOutlet weak var bottomLineLabel: UILabel!
    
    @IBOutlet weak var switchView: UISwitch!
    @IBAction func switchAction(_ sender: UISwitch) {
        let status = sender.isOn
        callback?(self, status, { (isOK ) -> Void in
            if isOK == false {
                self.switchView.setOn(false, animated: true)
                self.layoutIfNeeded()
            }
        })
    }
    
    func configCell(_ topline : String, bottomLine : String, status : Bool, complete : switchActionBlock?) {
        topLineLabel.text = topline
        bottomLineLabel.text = bottomLine
        switchView.isOn = status
        callback = complete
        
        if bottomLine.isEmpty {
            centerConstraint.priority = UILayoutPriority(rawValue: 750.0);
            bottomLineLabel.isHidden = true
            self.layoutIfNeeded()
        }
    }
}
