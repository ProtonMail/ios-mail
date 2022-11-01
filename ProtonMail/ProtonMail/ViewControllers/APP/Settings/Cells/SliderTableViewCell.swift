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

class SliderTableViewCell: UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }

    typealias SliderActionBlock = (Float) -> Void

    var callback: SliderActionBlock?
    var topLabel: UILabel!
    var bottomLabel: UILabel!
    var slider: UISlider!

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.createSubViews()
    }

    private func createSubViews() {
        self.topLabel = UILabel()
        self.topLabel.textColor = ColorProvider.TextNorm
        self.topLabel.font = UIFont.systemFont(ofSize: 17)
        self.topLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.topLabel)

        NSLayoutConstraint.activate([
            self.topLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 12),
            self.topLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -80),
            self.topLabel.widthAnchor.constraint(equalToConstant: 289.7),
            self.topLabel.heightAnchor.constraint(equalToConstant: 24),
            self.topLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16),
            self.topLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -89.3)
        ])

        self.bottomLabel = UILabel()
        self.bottomLabel.textColor = ColorProvider.TextWeak
        self.bottomLabel.font = UIFont.systemFont(ofSize: 13)
        self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.bottomLabel)

        NSLayoutConstraint.activate([
            self.bottomLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 84),
            self.bottomLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -16),
            self.bottomLabel.widthAnchor.constraint(equalToConstant: 343),
            self.bottomLabel.heightAnchor.constraint(equalToConstant: 16),
            self.bottomLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16),
            self.bottomLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -16)
        ])

        self.slider = UISlider()
        self.slider.translatesAutoresizingMaskIntoConstraints = false
        self.slider.minimumTrackTintColor = ColorProvider.BrandNorm
        self.slider.addTarget(self, action: #selector(self.sliderValueChanged(_:)), for: .valueChanged)
        self.addSubview(self.slider)

        NSLayoutConstraint.activate([
            self.slider.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 64),
            self.slider.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -48),
            self.slider.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16),
            self.slider.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -16)
        ])
    }

    @objc
    func sliderValueChanged(_ sender: UISlider) {
        self.callback?(sender.value)
    }

    func configCell(topLine: String,
                    bottomLine: String,
                    currentSliderValue: Float,
                    sliderMinValue: Float,
                    sliderMaxValue: Float,
                    complete: SliderActionBlock?) {
        topLabel.text = topLine
        bottomLabel.text = bottomLine

        self.slider.setValue(currentSliderValue, animated: false)
        self.slider.minimumValue = sliderMinValue
        self.slider.maximumValue = sliderMaxValue
        callback = complete

        self.layoutIfNeeded()
    }
}
