//
//  ContactsTableViewCell.swift
//  ProtonMail
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



import Foundation
import UIKit
import MCSwipeTableViewCell


/// Custom cell for Contact list, Group list and composer autocomplete
final class ContactsTableViewCell: MCSwipeTableViewCell {
    
    /// easiler to access
    static let cellID = "ContactCell"
    static var nib : UINib {
        return UINib(nibName: "ContactsTableViewCell", bundle: Bundle.main)
    }
    
    /// contact name, fill email if name is nil
    @IBOutlet weak var nameLabel: UILabel!
    /// contact email address
    @IBOutlet weak var emailLabel: UILabel!
    /// cell reused in contact groups. if the cell in the group list. show group icon and hides the shortNam label.
    @IBOutlet weak var groupImage: UIImageView!
    /// short name label, use the first char from name/email
    @IBOutlet weak var shortName: UILabel!
    
    override func awakeFromNib() {
        // 20 because the width is 40 hard coded
        self.shortName.layer.cornerRadius = 20
    }
    
    /// config cell when cellForRowAt
    ///
    /// - Parameters:
    ///   - name: contact name.
    ///   - email: contact email.
    ///   - highlight: hightlight string. autocomplete in composer
    ///   - color: contact group color -- String type and optional
    func config(name: String, email: String, highlight: String, color : String? = nil) {
        if highlight.isEmpty {
            self.nameLabel.attributedText = nil
            self.nameLabel.text = name
            
            self.emailLabel.attributedText = nil
            self.emailLabel.text = email
        } else {
            self.nameLabel.attributedText = .highlightedString(text: name,
                                                               search: highlight,
                                                               font: .highlightSearchTextForTitle)
            self.emailLabel.attributedText = .highlightedString(text: email,
                                                                search: highlight,
                                                                font: .highlightSearchTextForSubtitle)
        }
        
        //will be show the image
        if let color = color {
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
