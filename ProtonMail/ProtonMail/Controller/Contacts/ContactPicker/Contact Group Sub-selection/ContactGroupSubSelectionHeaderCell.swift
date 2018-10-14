//
//  ContactGroupSubSelectionHeaderCell.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/13.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactGroupSubSelectionHeaderCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBOutlet weak var selectionButton: UIButton!
    @IBOutlet weak var contactGroupIcon: UIImageView!
    @IBOutlet weak var contactGroupName: UILabel!
    
    private var delegate: ContactGroupSubSelectionViewModelHeaderCellDelegate!
    private var isAllSelected: Bool = false {
        didSet {
            if self.isAllSelected {
                selectionButton.setImage(UIImage.init(named: "mail_check-active"),
                                         for: .normal)
            } else {
                selectionButton.setImage(UIImage.init(named: "mail_check"),
                                         for: .normal)
            }
        }
    }
    
    func config(groupName: String,
                groupColor: String?,
                delegate: ContactGroupSubSelectionViewModelHeaderCellDelegate) {
        contactGroupName.text = groupName
        self.delegate = delegate
        
        if let color = groupColor {
            contactGroupIcon.setupImage(scale: 0.8,
                                        makeCircleBorder: true,
                                        tintColor: UIColor.white,
                                        backgroundColor: color)
        } else {
            contactGroupIcon.isHidden = true
        }
        
        self.isAllSelected = delegate.isAllSelected()
        if self.isAllSelected {
            // TODO: check the box
        }
    }
    
    @IBAction func tappedSelectAllButton(_ sender: UIButton) {
        self.isAllSelected = !self.isAllSelected
        
        if isAllSelected {
            delegate.selectAll()
        } else {
            delegate.deSelectAll()
        }
    }
}
