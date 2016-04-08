//
//  CustomHeaderView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {
    
    typealias switchActionBlock = (cell: SwitchTableViewCell!, newStatus: Bool, feedback: ActionStatus) -> Void
    typealias ActionStatus = (isOK: Bool) -> Void
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    var callback : switchActionBlock?
    
    @IBOutlet weak var centerConstraint: NSLayoutConstraint!
    @IBOutlet weak var topLineLabel: UILabel!
    @IBOutlet weak var bottomLineLabel: UILabel!
    
    @IBOutlet weak var switchView: UISwitch!
    @IBAction func switchAction(sender: UISwitch) {
        let status = sender.on
        callback?(cell: self, newStatus : status, feedback: { (isOK ) -> Void in
            if isOK == false {
                self.switchView.on = !status
            }
        })
    }
    
    func configCell(topline : String, bottomLine : String, status : Bool, complete : switchActionBlock?) {
        topLineLabel.text = topline
        bottomLineLabel.text = bottomLine
        switchView.on = status
        callback = complete
        
        if bottomLine.isEmpty {
            centerConstraint.priority = 750.0;
            bottomLineLabel.hidden = true
            self.layoutIfNeeded()
        }
    }
}
