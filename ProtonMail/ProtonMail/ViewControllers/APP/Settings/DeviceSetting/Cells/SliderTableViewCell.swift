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

@IBDesignable class SliderTableViewCell: UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }
    //typealias ActionStatus = (_ value: Float) -> Void
    typealias sliderActionBlock = (_ cell: SliderTableViewCell?, _ newValue: Float) -> Void
    var callback: sliderActionBlock?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //TODO changes to UI
        //slider.setValue(600, animated: false)
    }
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let value: Float = sender.value
        print("slider: \(sender.value)")
        callback?(self, value)
    }
    
    func configCell(_ topLine: String, _ bottomLine: String, currentValue sliderValue: Float, maxValue sliderMaxValue: Float, minValue sliderMinValue: Float, complete: sliderActionBlock?) {
        
        topLabel.text = topLine
        bottomLabel.text = bottomLine
        slider.isContinuous = false
        slider.setValue(sliderValue, animated: false)
        slider.minimumValue = sliderMinValue
        slider.maximumValue = sliderMaxValue
        callback = complete
        
        self.layoutIfNeeded()
    }
}

extension SliderTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
