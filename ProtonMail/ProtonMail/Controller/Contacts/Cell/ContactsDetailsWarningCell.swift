//
//  ContactsWarningTableViewCell.swift
//  Proton Mail - Created on 2/21/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

enum WarningType: Int {
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

    func configCell(warning: WarningType) {
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
