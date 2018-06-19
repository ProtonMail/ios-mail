//
//  ContactEditAddCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


final class ContactEditAddCell: UITableViewCell {
    
    @IBOutlet weak var valueLabel: UILabel!

    func configCell(value : String) {
        self.valueLabel.text = value
    }
    
}
