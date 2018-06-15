//
//  ContactEditEmailCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



final class ExpirationWarningEmailCell: UITableViewCell {
    
    @IBOutlet weak var emailLabel: UILabel!
    //
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configCell(email : String) {
        emailLabel.text = email
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
