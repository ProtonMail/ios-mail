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

class SpinnerTableViewCell: UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }

    var topLabel: UILabel!
    var bottomLabel: UILabel!
    var activityIndicator: UIActivityIndicatorView!

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
        self.topLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.topLabel)

        NSLayoutConstraint.activate([
            self.topLabel.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 12),
            self.topLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.topLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: 69.3)
        ])

        self.activityIndicator = UIActivityIndicatorView()
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.activityIndicator)

        NSLayoutConstraint.activate([
            self.activityIndicator.topAnchor.constraint(equalTo: self.topLabel.bottomAnchor, constant: 20.67),
            self.activityIndicator.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.activityIndicator.widthAnchor.constraint(equalToConstant: 32),
            self.activityIndicator.heightAnchor.constraint(equalToConstant: 32)
        ])

        self.bottomLabel = UILabel()
        self.bottomLabel.textColor = ColorProvider.TextWeak
        self.bottomLabel.font = UIFont.systemFont(ofSize: 13)
        self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.bottomLabel)

        NSLayoutConstraint.activate([
            self.bottomLabel.topAnchor.constraint(equalTo: self.topLabel.bottomAnchor, constant: 26),
            self.bottomLabel.leadingAnchor.constraint(equalTo: self.activityIndicator.trailingAnchor, constant: 12),
            self.bottomLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -12)
        ])
    }

    func configCell(_ topLine: String, _ bottomLine: String) {
        topLabel.text = topLine
        bottomLabel.text = bottomLine
        activityIndicator.startAnimating()
        self.layoutIfNeeded()
    }
}
