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
import MCSwipeTableViewCell

final class ContactsTableViewCell: MCSwipeTableViewCell {
    
    @IBOutlet var contactNameLabel: UILabel!
    @IBOutlet var contactEmailLabel: UILabel!
    @IBOutlet var contactSourceImageView: UIImageView!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var shortName: UILabel!
    
    override func awakeFromNib() {
        self.shortName.layer.cornerRadius = 20
    }
    
    func config(name: String, email: String, highlight: String, color : String? = nil) {
        if highlight.isEmpty {
            self.contactNameLabel.attributedText = nil
            self.contactNameLabel.text = name
            
            self.contactEmailLabel.attributedText = nil
            self.contactEmailLabel.text = email
        } else {
            self.contactNameLabel.attributedText = .highlightedString(text: name,
                                                                      search: highlight,
                                                                      font: .highlightSearchTextForTitle)
            self.contactEmailLabel.attributedText = .highlightedString(text: email,
                                                                       search: highlight,
                                                                       font: .highlightSearchTextForSubtitle)
        }
        
        if let color = color { //will be show the image
            groupImage.setupImage(tintColor: UIColor.white,
                                  backgroundColor: UIColor(hexColorCode: color),
                                  borderWidth: 0,
                                  borderColor: UIColor.white.cgColor)
            self.groupImage.isHidden = false
        } else {
            self.groupImage.isHidden = true
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
}
