//
//  ContactSectionHeadView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/14/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import UIKit

class ContactSectionHeadView: UITableViewHeaderFooterView {
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var signMark: UIImageView!

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    func ConfigHeader(title : String, signed : Bool) {
        headerLabel.text = title
        signMark.isHidden = !signed
        
        //disable for now 
        signMark.isHidden = true
    }

}
