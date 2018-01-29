//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation
import UIKit

final class ContactsTableViewCell: MCSwipeTableViewCell {

    @IBOutlet var contactNameLabel: UILabel!
    @IBOutlet var contactEmailLabel: UILabel!
    @IBOutlet var contactSourceImageView: UIImageView!
    
    @IBOutlet weak var shortName: UILabel!
    
    override func awakeFromNib() {
        self.shortName.layer.cornerRadius = 20
    }
    
    func config(name: String, email: String, highlight: String) {
        if highlight.isEmpty {
            self.contactNameLabel.attributedText = nil
            self.contactEmailLabel.attributedText = nil
            self.contactNameLabel.text = name
            self.contactEmailLabel.text = email
        } else {
            self.contactNameLabel.attributedText = self.highlightedAttributedString(text: name,
                                                                                    search: highlight,
                                                                                    font: Fonts.h2.bold)
            self.contactEmailLabel.attributedText = self.highlightedAttributedString(text: email,
                                                                                     search: highlight,
                                                                                     font: Fonts.h5.bold)
        }
        
        var shortn: String = ""
        if !name.isEmpty {
            let index = name.index(name.startIndex, offsetBy: 1)
            shortn = String(name[..<index])
        } else if !email.isEmpty {
            let index = email.index(email.startIndex, offsetBy: 1)
            shortn = String(email[..<index])
        }
        
        shortName.text = shortn.uppercased()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            shortName.backgroundColor = UIColor(hexColorCode: "#BFBFBF")
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            shortName.backgroundColor = UIColor(hexColorCode: "#BFBFBF")
        } else {
            shortName.backgroundColor = UIColor(hexColorCode: "#9497CE")
        }
    }
    
    private func highlightedAttributedString(text: String, search: String, font: UIFont) -> NSMutableAttributedString{
        let searchTerm = search /* SEARCH_TERM */
        let resultText = text /* YOUR_RESULT_TEXT */
        let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: resultText)
        let pattern = "(\(searchTerm))"
        let range:NSRange = NSMakeRange(0, resultText.count)
        let regex = try! NSRegularExpression( pattern: pattern, options: .caseInsensitive)
        regex.enumerateMatches(
            in: resultText,
            options: NSRegularExpression.MatchingOptions(),
            range: range,
            using: { (textCheckingResult, matchingFlags, stop) -> Void in
                let subRange = textCheckingResult?.range
                attributedString.addAttribute(NSAttributedStringKey.foregroundColor,
                                              value: UIColor.ProtonMail.Blue_6789AB,
                                              range: subRange!)
                
                attributedString.addAttribute(NSAttributedStringKey.font,
                                              value: font,
                                              range: subRange!)
        })
        return attributedString
    }
}
