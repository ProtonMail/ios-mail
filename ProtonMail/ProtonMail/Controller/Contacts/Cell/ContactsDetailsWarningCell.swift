//
//  ContactsWarningTableViewCell.swift
//  ProtonMail - Created on 2/21/18.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
