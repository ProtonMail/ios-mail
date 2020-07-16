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

protocol MenuUserViewCellDelegate: class {
    func didClickedSignInButton(cell: MenuUserViewCell)
}

class MenuUserViewCell: UITableViewCell {
    
    weak var delegate: MenuUserViewCellDelegate?
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var emailAddress: UILabel!
    @IBOutlet weak var shortName: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    @IBOutlet weak var separtor: UIView!
    
    @IBOutlet weak var signOutBtn: UIButton!
    
    @IBOutlet weak var displayNameTrailingToUnreadLeading: NSLayoutConstraint!
    @IBOutlet weak var userEmailTrailingToUnreadLeading: NSLayoutConstraint!
    
    
    //    fileprivate var item: MenuItem!
    @IBOutlet weak var displayNameToSignIn: NSLayoutConstraint!
    @IBOutlet weak var userEmailTrailingToSignInLeading: NSLayoutConstraint!
    
    enum CellType {
        case LoggedIn
        case LoggedOut
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.zeroMargin()
        
        let selectedBackgroundView = UIView(frame: CGRect.zero)
        selectedBackgroundView.backgroundColor = UIColor.ProtonMail.Menu_SelectedBackground
        
        self.selectedBackgroundView = selectedBackgroundView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundImage.layer.cornerRadius = self.backgroundImage.frame.width / 2
        self.signOutBtn.layer.cornerRadius = 4.0
        self.signOutBtn.layer.masksToBounds = true
    }
    
    func configCell(type: CellType, name: String, email: String) {
        switch type {
        case .LoggedIn:
            unreadLabel.isHidden = false
            signOutBtn.isHidden = true
            
            displayNameTrailingToUnreadLeading.priority = UILayoutPriority(rawValue: 999)
            userEmailTrailingToUnreadLeading.priority = UILayoutPriority(rawValue: 999)
            
            displayNameToSignIn.priority = .defaultLow
            userEmailTrailingToSignInLeading.priority = .defaultLow
            
            self.displayName.textColor = .black
            self.emailAddress.textColor = .black
            
            configCell(name: name, email: email)
            
        case .LoggedOut:
            unreadLabel.isHidden = true
            signOutBtn.isHidden = false
            
            displayNameTrailingToUnreadLeading.priority = .defaultLow
            userEmailTrailingToUnreadLeading.priority = .defaultLow
            
            displayNameToSignIn.priority = UILayoutPriority(rawValue: 999)
            userEmailTrailingToSignInLeading.priority = UILayoutPriority(rawValue: 999)
            
            self.displayName.textColor = .red
            self.emailAddress.textColor = .red
            
            configCell(name: name, email: email)
        }
    }
    
    private func configCell (name: String, email: String) {
        
        unreadLabel.layer.masksToBounds = true;
        unreadLabel.layer.cornerRadius = 12;
        unreadLabel.text = "0";
        
        let displayName = name.isEmpty ? email : name
        self.displayName.text = displayName
        self.emailAddress.text = email
        self.setupShortName(displayName: displayName)
    }
    
    private func setupShortName(displayName: String) {
        var shortName = ""
        let splitCharacterOfName = displayName
                                    .split(separator: " ")
                                    .compactMap { $0.first?.uppercased() }
        let upperbound = min(2, splitCharacterOfName.count)
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
    
    func configUnreadCount (count: Int) {
        if count > 0 {
            unreadLabel.text = "\(count)";
            unreadLabel.isHidden = false;
        } else {
            unreadLabel.text = "0";
            unreadLabel.isHidden = true;
        }
    }
    
    func hideSepartor(_ hideSepartor: Bool) {
        separtor.isHidden = hideSepartor
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        separtor.isHidden = true
    }
    
    @IBAction func handleSignIn(_ sender: Any) {
        self.delegate?.didClickedSignInButton(cell: self)
    }
}
