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

@IBDesignable class ProgressBarButtonTableViewCell: UITableViewCell {
    static var CellID : String {
        return "\(self)"
    }
    typealias ActionStatus = (_ status: Bool) -> Void
    typealias buttonActionBlock = (_ cell: ProgressBarButtonTableViewCell?, _ newStatus: Bool, _ feedback: @escaping ActionStatus) -> Void
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //TODO some UI changes to progress view and button?
    }
    
    var callback : buttonActionBlock?
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var estimatedTimeLabel: UILabel!
    @IBOutlet weak var currentProgressLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    
    @IBAction func pauseButtonPressed(_ sender: UIButton) {
        //let status = sender.
        print("Button pressed!")
    }
    
    func configCell(_ titleLine: String, _ topLine: String, _ estimatedTime: Int, _ currentProgress: Int, _ textButtonNormal: String, _ textButtonPressed: String, complete: buttonActionBlock?) {
        
        titleLabel.text = titleLine
        topLabel.text = topLine
        estimatedTimeLabel.text = String(estimatedTime) + " minutes remaining..."
        currentProgressLabel.text = String(currentProgress) + "%"
        progressView.progress = Float(currentProgress)/100.0
        pauseButton.setTitle(textButtonNormal, for: UIControl.State.normal)
        pauseButton.setTitle(textButtonPressed, for: UIControl.State.selected)
        
        //implementation of pause button
        callback = complete
        
        self.layoutIfNeeded()
    }
    
}

extension ProgressBarButtonTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
