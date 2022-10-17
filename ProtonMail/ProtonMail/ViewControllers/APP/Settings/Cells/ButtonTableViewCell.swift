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

class ButtonTableViewCell: UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }

    typealias ButtonActionBlock = () -> Void

    var callback: ButtonActionBlock?
    var topLabel: UILabel!
    var bottomLabel: UILabel!
    var button: UIButton!

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.createSubViews()
    }

    private func createSubViews() {
        let parentView: UIView = self.contentView

        self.topLabel = UILabel()
        self.topLabel.textColor = ColorProvider.TextNorm
        self.topLabel.font = UIFont.systemFont(ofSize: 17)
        self.topLabel.numberOfLines = 1
        self.topLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.topLabel)

        NSLayoutConstraint.activate([
            self.topLabel.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 16),
            self.topLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.topLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16)
        ])

        self.bottomLabel = UILabel()
        self.bottomLabel.textColor = ColorProvider.TextNorm
        self.bottomLabel.font = UIFont.systemFont(ofSize: 14)
        self.bottomLabel.numberOfLines = 1
        self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.bottomLabel)

        NSLayoutConstraint.activate([
            self.bottomLabel.topAnchor.constraint(equalTo: self.topLabel.bottomAnchor, constant: 14),
            self.bottomLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.bottomLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -96)
        ])

        self.button = UIButton()
        self.button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        self.button.titleLabel?.numberOfLines = 1
        self.button.setTitleColor(ColorProvider.TextNorm, for: .normal)
        self.button.tintColor = ColorProvider.InteractionWeak
        self.button.backgroundColor = ColorProvider.InteractionWeak
        self.button.layer.cornerRadius = 8
        self.button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        self.button.frame.size = CGSize(width: 32.0, height: 16.0)
        self.button.addTarget(self, action: #selector(self.buttonPressed(_:)), for: .touchUpInside)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.button)

        NSLayoutConstraint.activate([
            self.button.centerYAnchor.constraint(equalTo: self.bottomLabel.centerYAnchor),
            self.button.rightAnchor.constraint(equalTo: parentView.rightAnchor, constant: -16),
            self.button.leftAnchor.constraint(equalTo: parentView.leftAnchor, constant: 327)
        ])
    }

    @objc
    func buttonPressed(_ sender: UIButton) {
        callback?()
    }

    func configCell(_ topLine: String,
                    _ bottomLine: NSMutableAttributedString,
                    _ titleOfButton: String,
                    complete: ButtonActionBlock?) {
        topLabel.text = topLine
        bottomLabel.attributedText = bottomLine
        button.setTitle(titleOfButton, for: .normal)
        callback = complete

        self.layoutIfNeeded()
    }
}
