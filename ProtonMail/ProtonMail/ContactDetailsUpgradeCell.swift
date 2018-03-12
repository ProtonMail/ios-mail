//
//  ContactDetailsUpgradeCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 1/8/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation



final class ContactDetailsUpgradeCell: UITableViewCell {
    
    @IBOutlet weak var frameView: UIView!
    
    @IBOutlet weak var upgradeButton: UIButton!
    
//    fileprivate let upgradePageUrl = URL(string: "https://protonmail.com/upgrade")!
    
    private var delegate: ContactUpgradeCellDelegate?
    
    override func awakeFromNib() {
        let color = UIColor(hexColorCode: "#9497CE")
        frameView.layer.borderColor = color.cgColor
        frameView.layer.borderWidth = 1.0
        frameView.layer.cornerRadius = 4.0
        frameView.clipsToBounds = true
        upgradeButton.roundCorners()
    }
    @IBAction func upgradeAction(_ sender: Any) {
//        UIApplication.shared.openURL(upgradePageUrl)
        self.delegate?.upgrade()
    }
    
    func configCell(delegate: ContactUpgradeCellDelegate?) {
        self.delegate = delegate
    }
}
