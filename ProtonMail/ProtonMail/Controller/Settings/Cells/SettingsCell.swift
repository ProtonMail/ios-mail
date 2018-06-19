//
//  SettingsCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/16/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


class SettingsCell : UITableViewCell {
    
    @IBOutlet weak var LeftText: UILabel!
    @IBOutlet weak var RightText: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

