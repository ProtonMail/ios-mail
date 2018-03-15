//
//  ContactsWarningTableViewCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/21/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

enum WarningType : Int {
    case signatureWarning = 1
    case decryptionError = 2
}

class ContactsDetailsWarningCell: UITableViewCell {

    @IBOutlet weak var warningImage: UIImageView!
    @IBOutlet weak var errorTitle: UILabel!
    @IBOutlet weak var errorDetails: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configCell(warning : WarningType) {
        switch warning {
        case .signatureWarning:
            self.errorTitle.text = NSLocalizedString("Verification error", comment: "error title")
            self.errorDetails.text = NSLocalizedString("Verification of this content’s signature failed", comment: "error details")
        case .decryptionError:
            self.errorTitle.text = NSLocalizedString("Decryption error", comment: "error title")
            self.errorDetails.text = NSLocalizedString("Decryption of this content failed", comment: "error details")
        }
    }
    
    func configCell(forlog: String) {
        self.errorTitle.text = NSLocalizedString("Logs", comment: "error title")
        self.errorDetails.text = forlog
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
