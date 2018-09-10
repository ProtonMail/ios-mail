//
//  ContactGroupsViewCell.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/5.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactGroupsViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
        
    let highlightedColor = "#BFBFBF"
    let normalColor = "#9497CE"
    
    var name = ""
    var detail = ""
    var color = ColorManager.defaultColor
    
    
    @IBAction func sendEmailButtonTapped(_ sender: UIButton) {
        // TODO
        
        let alert = UIAlertController(title: "Send an email to \(name)",
            message: "Code to be implemented",
            preferredStyle: .alert)
        alert.addOKAction()
        
        UIApplication.shared.keyWindow?.rootViewController?.present(alert,
                                                                    animated: true,
                                                                    completion: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.groupImage.layer.cornerRadius = 20.0
    }

    func config(name: String, count: Int, color: String?) {
        // setup and save
        let detail = "\(count) Member\(count > 1 ? "s" : "")"
        
        self.name = name
        self.detail = detail
        self.color = color ?? ColorManager.defaultColor
        
        // set cell data
        self.nameLabel.text = name
        self.detailLabel.text = detail
        if let color = color {
            groupImage.backgroundColor = UIColor(hexColorCode: color)
        } else {
            groupImage.backgroundColor = UIColor(hexColorCode: ColorManager.defaultColor)
        }
    }
    
    private func reset() {
        nameLabel.text = name
        detailLabel.text = detail
        groupImage.backgroundColor = UIColor(hexColorCode: color)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            groupImage.backgroundColor = UIColor(hexColorCode: highlightedColor)
        } else {
            reset()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            groupImage.backgroundColor = UIColor(hexColorCode: highlightedColor)
        } else {
            reset()
        }
    }
}
