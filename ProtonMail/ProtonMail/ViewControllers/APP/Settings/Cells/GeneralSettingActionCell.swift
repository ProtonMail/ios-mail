//
//  GeneralSettingActionCell.swift
//  Proton Mail
//
//  Proton Mail - Created on 2020/4/15.
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

class GeneralSettingActionCell: UITableViewCell {
    @IBOutlet weak var leftText: UILabel!
    @IBOutlet weak var actionButton: UIButton!

    private var callBack: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.actionButton.layer.cornerRadius = 4.0
        self.actionButton.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func handleAction(_ sender: Any) {
        self.callBack?()
    }
}
