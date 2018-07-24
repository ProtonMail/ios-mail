//
//  ExpirationWarningHeaderCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/14/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import UIKit

protocol ExpirationWarningHeaderCellDelegate {
    func clicked(at section : Int, expend: Bool)
}

class ExpirationWarningHeaderCell: UITableViewHeaderFooterView {
    var delegate : ExpirationWarningHeaderCellDelegate?
    @IBOutlet weak var headerLabel: UILabel!
    var section : Int = 0
    var expend : Bool = false
    
    @IBOutlet weak var actionButton: UIButton!

    @IBOutlet weak var arrowImage: UIImageView!
    @IBAction func backgroundAction(_ sender: Any) {
        if self.expend {
            self.expend = false
            self.updateImage()
            delegate?.clicked(at: self.section, expend: self.expend)
        } else {
            self.expend = true
            self.updateImage()
            delegate?.clicked(at: self.section, expend: self.expend)
        }
    }
    
    func ConfigHeader(title : String, section : Int, expend : Bool) {
        headerLabel.text = title
        self.section = section
        self.expend = expend
        self.updateImage()
    }

    func updateImage() {
        if self.expend {
            self.arrowImage.image = UIImage(named: "mail_attachment-closed")
        } else {
            self.arrowImage.image = UIImage(named: "mail_attachment-open")
        }
    }
}
