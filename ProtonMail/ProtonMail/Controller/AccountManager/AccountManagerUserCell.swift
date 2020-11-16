//
//  MenuTableViewCell.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

class AccountManagerUserCell: UITableViewCell, AccessibleCell {
    
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var diaplayName: UILabel!
    @IBOutlet weak var emailAddress: UILabel!
    @IBOutlet weak var shortName: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.zeroMargin()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundImage.layer.cornerRadius = self.backgroundImage.frame.width / 2
    }
    
    func configCell (name: String, email: String) {
        diaplayName.textColor = .black
        emailAddress.textColor = .black
        unreadLabel.layer.masksToBounds = true;
        unreadLabel.layer.cornerRadius = 12;
        unreadLabel.text = "0";
        
        let displayName = name.isEmpty ? email : name
        diaplayName.text = displayName
        emailAddress.text = email
        self.setupShortName(displayName: displayName)
        generateCellAccessibilityIdentifiers(email)
    }
    
    private func setupShortName(displayName: String) {
        var shortName = ""
        let splitCharacterOfName = displayName
                                    .split(separator: " ")
                                    .compactMap { $0.first?.uppercased() }
        let upperbound = min(splitCharacterOfName.count, 2)
        for i in 0..<upperbound {
            shortName.append(splitCharacterOfName[i])
        }
        self.shortName.text = shortName
        if shortName.containsEmoji {
            self.shortName.font = .systemFont(ofSize: 14)
            self.shortName.baselineAdjustment = .alignCenters
        } else {
            self.shortName.font = .systemFont(ofSize: 18)
            self.shortName.baselineAdjustment = .alignBaselines
        }
    }
    
    func configLoggedOutCell(name: String, email: String) {
        self.configCell(name: name, email: email)
        self.diaplayName.text = (diaplayName.text ?? "Unknown") + " " + LocalString._logged_out
        
        self.diaplayName.textColor = .red
        self.emailAddress.textColor = .red
        generateCellAccessibilityIdentifiers("\(email)_\(LocalString._logged_out)")
    }
    
    func configUnreadCount (count: Int) {
        if count > 0 {
            unreadLabel.text = "\(count)";
            unreadLabel.isHidden = false;
        } else {
            unreadLabel.text = "0";
            unreadLabel.isHidden = true;
        }
    }
    
    func hideCount () {
        unreadLabel.text = "0";
        unreadLabel.isHidden = true;
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            unreadLabel.backgroundColor = UIColor.ProtonMail.Menu_UnreadCountBackground
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            unreadLabel.backgroundColor = UIColor.ProtonMail.Menu_UnreadCountBackground
        }
    }
}
