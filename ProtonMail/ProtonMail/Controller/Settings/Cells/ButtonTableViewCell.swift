// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

@IBDesignable class ButtonTableViewCell: UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        //let status = sender.
        print("button pressed!")
    }
    
    func configCell(_ topLine: String, _ bottomLine: String, _ titleOfButton: String) {
        topLabel.text = topLine
        bottomLabel.text = bottomLine
        button.setTitle(titleOfButton, for: .normal)
        
        self.layoutIfNeeded()
    }
}

extension ButtonTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}

