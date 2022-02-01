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

    typealias sliderActionBlock = (Float) -> Void
    var callback: sliderActionBlock?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.topLabel.textColor = ColorProvider.TextNorm
        self.topLabel.font = UIFont.systemFont(ofSize: 17)
        self.topLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 12),
            self.topLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -80),
            self.topLabel.widthAnchor.constraint(equalToConstant: 289.7),
            self.topLabel.heightAnchor.constraint(equalToConstant: 24),
            self.topLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16),
            self.topLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -89.3)
        ])

        self.bottomLabel.textColor = ColorProvider.TextWeak
        self.bottomLabel.font = UIFont.systemFont(ofSize: 13)
        self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.bottomLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 84),
            self.bottomLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -16),
            self.bottomLabel.widthAnchor.constraint(equalToConstant: 343),
            self.bottomLabel.heightAnchor.constraint(equalToConstant: 16),
            self.bottomLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16),
            self.bottomLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -16)
        ])

        self.slider.translatesAutoresizingMaskIntoConstraints = false
        self.slider.minimumTrackTintColor = ColorProvider.BrandNorm
        NSLayoutConstraint.activate([
            self.slider.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 64),
            self.slider.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -48),
            self.slider.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16),
            self.slider.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -16)
        ])
    }

    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var slider: UISlider!

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        self.callback?(sender.value)
    }

    func configCell(topLine: String, bottomLine: String, currentSliderValue: Float, sliderMinValue: Float, sliderMaxValue: Float, complete: sliderActionBlock?) {
        topLabel.text = topLine
        bottomLabel.text = bottomLine

        self.slider.setValue(currentSliderValue, animated: false)
        self.slider.minimumValue = sliderMinValue
        self.slider.maximumValue = sliderMaxValue
        callback = complete

        self.layoutIfNeeded()
    }
}

extension SliderTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
