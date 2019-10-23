//
//  ForceUpgradeView.swift
//  ProtonMail - Created on 09/11/18.
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

protocol ForceUpgradeViewDelegate : AnyObject {
    func learnMore()
    func update()
}

class ForceUpgradeView : PMView {
    weak var delegate : ForceUpgradeViewDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var learnMoreButton: UIButton!
    @IBOutlet weak var updateButton: UIButton!
    
    override func getNibName() -> String {
        return "ForceUpgradeView"
    }

    override func setup() {
        //set localized strings
        self.titleLabel.text = LocalString._update_required
        self.learnMoreButton.setTitle(LocalString._learn_more, for: .normal)
        self.updateButton.setTitle(LocalString._update_now, for: .normal)
    }

    @IBAction func updateAction(_ sender: AnyObject) {
        delegate?.update()
    }
    
    @IBAction func learnMoreAction(_ sender: AnyObject) {
        delegate?.learnMore()
    }
}

