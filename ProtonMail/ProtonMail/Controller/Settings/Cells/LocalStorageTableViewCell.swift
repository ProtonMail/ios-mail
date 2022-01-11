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

@IBDesignable class LocalStorageTableViewCell: UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }
    
    typealias buttonActionBlock = () -> Void
    var callback: buttonActionBlock?
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var middleLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        callback?()
    }
    
    func configCell(_ topLine: String, _ middleLine: String, _ bottomLine: String, _ complete: buttonActionBlock?) {
        topLabel.text = topLine
        middleLabel.text = middleLine
        bottomLabel.text = bottomLine
        callback = complete
        
        self.layoutIfNeeded()
    }
}

extension LocalStorageTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
