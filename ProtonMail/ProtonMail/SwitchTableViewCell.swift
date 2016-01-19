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

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var switchView: UISwitch!
    @IBAction func switchAction(sender: UISwitch) {
        
        sharedUserDataService.switchCacheOff = !sender.on
        //sharedUserData.switchCache = sender.on
    }
    
    func setUpSwitch(show : Bool, status : Bool) {
        if show {
           switchView.enabled = true
        } else {
            switchView.enabled = false
        }
        switchView.on = status;
    }
}
