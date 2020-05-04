//
//  GeneralSettingActionCell.swift
//  ProtonMail
//
//  ProtonMail - Created on 2020/4/15.
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

import UIKit

class GeneralSettingActionCell: UITableViewCell {
    @IBOutlet weak var leftText: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    static var CellID: String {
        return "\(self)"
    }
    
    private var callBack: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.actionButton.layer.cornerRadius = 4.0
        self.actionButton.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configCell(left: String, action: String, callback: (() -> ())?) {
        self.leftText.text = left
        self.callBack = callback
        
        self.actionButton.setTitle(action, for: .normal)
    }
    
    @IBAction func handleAction(_ sender: Any) {
        self.callBack?()
    }
}
