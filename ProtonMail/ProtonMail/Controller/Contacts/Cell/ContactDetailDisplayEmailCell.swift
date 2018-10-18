//
//  ContactDetailDisplayEmailCell.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/10.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactDetailDisplayEmailCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var value: UILabel!
    @IBOutlet weak var iconStackView: UIStackView!
    @IBOutlet weak var iconStackViewWidthConstraint: NSLayoutConstraint!
    
    func configCell(title: String, value: String, contactGroupColors: [String]) {        
        self.title.text = title
        self.value.text = value
        
        prepareContactGroupIcons(cell: self,
                                 contactGroupColors: contactGroupColors,
                                 iconStackView: iconStackView,
                                 iconStackViewWidthConstraint: iconStackViewWidthConstraint)
    }
}

extension ContactDetailDisplayEmailCell: ContactCellShare {}
