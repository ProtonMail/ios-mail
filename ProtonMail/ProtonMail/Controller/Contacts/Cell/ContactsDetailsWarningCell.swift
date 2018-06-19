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
            self.errorTitle.text = LocalString._verification_error
            self.errorDetails.text = LocalString._verification_of_this_contents_signature_failed
        case .decryptionError:
            self.errorTitle.text = LocalString._decryption_error
            self.errorDetails.text = LocalString._decryption_of_this_content_failed
        }
    }
    
    func configCell(forlog: String) {
        self.errorTitle.text = LocalString._logs
        self.errorDetails.text = forlog
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
