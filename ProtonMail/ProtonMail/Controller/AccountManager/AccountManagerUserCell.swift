//
//  MenuTableViewCell.swift
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

class AccountManagerUserCell: UITableViewCell {
    
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var diaplayName: UILabel!
    @IBOutlet weak var emailAddress: UILabel!
    @IBOutlet weak var shortName: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    
    
//    fileprivate var item: MenuItem!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.zeroMargin()
        
        let selectedBackgroundView = UIView(frame: CGRect.zero)
        selectedBackgroundView.backgroundColor = UIColor.ProtonMail.Menu_SelectedBackground
        
        self.selectedBackgroundView = selectedBackgroundView
    }
    
    func configCell (name: String, email: String) {
        
        unreadLabel.layer.masksToBounds = true;
        unreadLabel.layer.cornerRadius = 12;
        unreadLabel.text = "0";
        
        let displayName = name.isEmpty ? email : name
        diaplayName.text = displayName
        emailAddress.text = email
        var shortName = ""
        if displayName.count > 0 {
            shortName = String(displayName[name.startIndex])
        }
        self.shortName.text = shortName
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
