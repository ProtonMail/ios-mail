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
    func sendEmailToGroup(ID: String, name: String)
}

class ContactGroupsViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var sendButton: UIButton!
    
    let highlightedColor = "#BFBFBF"
    let normalColor = "#9497CE"
    
    private var labelID = ""
    private var name = ""
    private var detail = ""
    private var color = ColorManager.defaultColor
    private var delegate: ContactGroupsViewCellDelegate!
    
    @IBAction func sendEmailButtonTapped(_ sender: UIButton) {
        delegate.sendEmailToGroup(ID: labelID, name: name)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
        if let image = sendButton.imageView?.image {
            sendButton.imageView?.contentMode = .center
            sendButton.imageView?.image = UIImage.resize(image: image, targetSize: CGSize.init(width: 20, height: 20))
        }
        
        self.nameLabel.text = name
        self.detailLabel.text = detail
        groupImage.setupImage(tintColor: UIColor.white,
                              backgroundColor: color != nil ? color! : ColorManager.defaultColor,
                              borderWidth: 0,
                              borderColor: UIColor.white.cgColor)
    }
    
    private func reset() {
        nameLabel.text = name
        detailLabel.text = detail
        
        groupImage.image = UIImage(named: "contact_groups_icon")
        groupImage.setupImage(contentMode: .center,
                              renderingMode: .alwaysTemplate,
                              scale: 0.5,
                              makeCircleBorder: true,
                              tintColor: UIColor.white,
                              backgroundColor: color,
                              borderWidth: 0,
                              borderColor: UIColor.white.cgColor)
        
        self.selectionStyle = .default
    }
    
    func getLabelID() -> String {
        return labelID
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if delegate.isMultiSelect() && selected {
            // in multi-selection
            groupImage.image = UIImage(named: "contact_groups_check")
            groupImage.setupImage(contentMode: .center,
                                  renderingMode: .alwaysOriginal,
                                  scale: 0.5,
                                  makeCircleBorder: true,
                                  tintColor: UIColor.white,
                                  backgroundColor: ColorManager.white,
                                  borderWidth: 1.0,
                                  borderColor: UIColor.gray.cgColor)
        } else if delegate.isMultiSelect() == false && selected {
            // normal selection
            groupImage.backgroundColor = UIColor(hexColorCode: highlightedColor)
        } else {
            reset()
        }
    }
}
