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
        
    }
    
    func setUpSwitch(show : Bool) {
        if show {
           switchView.enabled = false
        } else {
            switchView.enabled = true
        }
    }
}
