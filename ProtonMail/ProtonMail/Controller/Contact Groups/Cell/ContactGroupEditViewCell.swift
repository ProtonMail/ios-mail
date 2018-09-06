//
//  ContactGroupEditViewCell.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/6.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactGroupEditViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var shortNameLabel: UILabel!
    
    var name: String = ""
    var email: String = ""
    var shortName: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        shortNameLabel.layer.cornerRadius = 20.0
    }
    
    func config(name: String, email: String) {
        self.name = name
        self.email = email
        
        nameLabel.text = name
        emailLabel.text = email
        
        if name.count > 0 {
            self.shortName = String(name[name.startIndex])
        } else {
            self.shortName = ""
        }
        shortNameLabel.text = self.shortName
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
