//
//  CustomHeaderView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBOutlet weak var centerConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var switchView: UISwitch!
    @IBAction func switchAction(sender: UISwitch) {
        sharedUserDataService.switchCacheOff = !sender.on
        self.updateStatus()
    }
    
    func setUpSwitch(show : Bool, status : Bool) {
        if show {
            switchView.enabled = true
        } else {
            switchView.enabled = false
        }
        switchView.on = status;
        self.updateStatus()
    }
    
    func updateStatus() {
        if let isOff = sharedUserDataService.switchCacheOff {
            if !isOff {
                centerConstraint.priority = 1.0;
                titleLabel.hidden = false
            } else {
                centerConstraint.priority = 750.0;
                titleLabel.hidden = true
            }
        }
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.layoutIfNeeded()
            }, completion: nil)
    }
}
