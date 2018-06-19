//
//  ContactDetailsEmailCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/3/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


final class ContactDetailsDisplayCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var value: UILabel!
    
    
    func configCell(title : String, value : String) {
        self.title.text = title
        self.value.text = value
    }
    
}
