//
//  ContactEditUpgradeCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 1/8/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

final class ContactEditUpgradeCell : UITableViewCell {
    
    @IBOutlet weak var frameView: UIView!
    @IBOutlet weak var upgradeButton: UIButton!
    
    
    override func awakeFromNib() {
        let color = UIColor(hexColorCode: "#9497CE")
        frameView.layer.borderColor = color.cgColor
        frameView.layer.borderWidth = 1.0
        frameView.layer.cornerRadius = 4.0
        frameView.clipsToBounds = true
        upgradeButton.roundCorners()
    }
}
