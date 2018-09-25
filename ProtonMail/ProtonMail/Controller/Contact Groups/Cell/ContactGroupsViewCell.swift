//
//  ContactGroupsViewCell.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/5.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

protocol ContactGroupsViewCellDelegate {
    func isMultiSelect() -> Bool
}

class ContactGroupsViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
        
    let highlightedColor = "#BFBFBF"
    let normalColor = "#9497CE"
    
    private var name = ""
    private var detail = ""
    private var color = ColorManager.defaultColor
    private var labelID = ""
    private var delegate: ContactGroupsViewCellDelegate!
    
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

    func config(labelID: String,
                name: String,
                count: Int,
                color: String?,
                delegate: ContactGroupsViewCellDelegate) {
        // setup and save
        let detail = "\(count) Member\(count > 1 ? "s" : "")"
        
        self.labelID = labelID
        self.name = name
        self.detail = detail
        self.color = color ?? ColorManager.defaultColor
        self.delegate = delegate
        
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
        
        groupImage.image = UIImage(named: "iap_users")
        groupImage.backgroundColor = UIColor(hexColorCode: color)
        groupImage.layer.borderWidth = 0
        groupImage.layer.borderColor = UIColor.white.cgColor
        
        self.selectionStyle = .default
    }
    
    func getLabelID() -> String {
        return labelID
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        print("ID \(labelID) isMultiSelect \(delegate.isMultiSelect()) selected \(selected)")
        
        if delegate.isMultiSelect() && selected {
            // in multi-selection
            groupImage.image = UIImage(named: "checked_signin")
            groupImage.layer.backgroundColor = UIColor.white.cgColor
            groupImage.layer.borderWidth = 1.0
            groupImage.layer.borderColor = UIColor.gray.cgColor
        } else if delegate.isMultiSelect() == false && selected {
            // normal selection
            groupImage.backgroundColor = UIColor(hexColorCode: highlightedColor)
        } else {
            reset()
        }
    }
}
