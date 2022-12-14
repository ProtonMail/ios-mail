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

class ProgressBarButtonTableViewCell: UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }

    typealias ButtonActionBlock = () -> Void

    var callback: ButtonActionBlock?
    var progressView: UIProgressView!
    var statusLabel: UILabel!
    var titleLabel: UILabel!
    var estimatedTimeLabel: UILabel!
    var currentProgressLabel: UILabel!
    var pauseButton: UIButton!
    var messageCountLabel: UILabel!

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.createSubViews()
    }

    // swiftlint:disable function_body_length
    private func createSubViews() {
        let parentView: UIView = self.contentView

        self.titleLabel = UILabel()
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.textColor = ColorProvider.TextNorm
        self.titleLabel.font = UIFont.systemFont(ofSize: 17)
        self.addSubview(self.titleLabel)

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 12),
            self.titleLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.titleLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16)
        ])

        self.progressView = UIProgressView()
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        self.progressView.progressTintColor = ColorProvider.BrandNorm
        self.addSubview(self.progressView)

        NSLayoutConstraint.activate([
            self.progressView.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 24),
            self.progressView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.progressView.trailingAnchor.constraint(equalTo: parentView.leadingAnchor,
                                                        constant: UIScreen.main.bounds.width - 16)
        ])

        self.estimatedTimeLabel = UILabel()
        self.estimatedTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.estimatedTimeLabel.textColor = ColorProvider.TextWeak
        self.estimatedTimeLabel.font = UIFont.systemFont(ofSize: 13)
        self.addSubview(self.estimatedTimeLabel)

        NSLayoutConstraint.activate([
            self.estimatedTimeLabel.topAnchor.constraint(equalTo: self.progressView.bottomAnchor, constant: 8),
            self.estimatedTimeLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.estimatedTimeLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16)
        ])

        self.currentProgressLabel = UILabel()
        self.currentProgressLabel.translatesAutoresizingMaskIntoConstraints = false
        self.currentProgressLabel.textAlignment = .right
        self.currentProgressLabel.textColor = ColorProvider.TextWeak
        self.currentProgressLabel.font = UIFont.systemFont(ofSize: 13)
        self.addSubview(self.currentProgressLabel)

        NSLayoutConstraint.activate([
            self.currentProgressLabel.topAnchor.constraint(equalTo: self.progressView.bottomAnchor,
                                                           constant: 8),
            self.currentProgressLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor,
                                                               constant: 16),
            self.currentProgressLabel.trailingAnchor.constraint(equalTo: parentView.leadingAnchor,
                                                                constant: UIScreen.main.bounds.width - 16)
        ])

        self.pauseButton = UIButton()
        self.pauseButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        self.pauseButton.titleLabel?.numberOfLines = 1
        self.pauseButton.setTitleColor(ColorProvider.TextNorm, for: .normal)
        self.pauseButton.tintColor = ColorProvider.InteractionWeak
        self.pauseButton.backgroundColor = ColorProvider.InteractionWeak
        self.pauseButton.layer.cornerRadius = 8
        self.pauseButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        self.pauseButton.frame.size = CGSize(width: 69.0, height: 32.0)
        self.pauseButton.addTarget(self, action: #selector(self.pauseButtonPressed(_:)), for: .touchUpInside)
        self.pauseButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.pauseButton)

        NSLayoutConstraint.activate([
            self.pauseButton.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.pauseButton.topAnchor.constraint(equalTo: self.estimatedTimeLabel.bottomAnchor, constant: 16)
        ])

        // status label is hidden by default
        self.statusLabel = UILabel()
        self.statusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.statusLabel.textColor = ColorProvider.TextWeak
        self.statusLabel.font = UIFont.systemFont(ofSize: 13)
        self.addSubview(self.statusLabel)

        NSLayoutConstraint.activate([
            self.statusLabel.topAnchor.constraint(equalTo: self.estimatedTimeLabel.bottomAnchor, constant: 16),
            self.statusLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.statusLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16)
        ])

        self.messageCountLabel = UILabel()
        self.messageCountLabel.translatesAutoresizingMaskIntoConstraints = false
        self.messageCountLabel.textColor = ColorProvider.TextWeak
        self.messageCountLabel.font = UIFont.systemFont(ofSize: 13)
        self.addSubview(self.messageCountLabel)

        NSLayoutConstraint.activate([
            self.messageCountLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 4),
            self.messageCountLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.messageCountLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16)
        ])

        self.layoutIfNeeded()
    }

    @objc
    func pauseButtonPressed(_ sender: UIButton) {
        callback?()
        self.layoutIfNeeded()
    }

    func configCell(_ titleLine: String,
                    _ advice: String,
                    _ estimatedTime: String,
                    _ currentProgress: Int,
                    _ buttonTitle: String,
                    _ messageCount: String,
                    complete: ButtonActionBlock?) {
        titleLabel.text = titleLine
        statusLabel.text = advice
        estimatedTimeLabel.text = estimatedTime
        currentProgressLabel.text = String(currentProgress) + "%"
        progressView.setProgress(Float(currentProgress) / 100.0, animated: true)
        self.pauseButton.setTitle(buttonTitle, for: UIControl.State.normal)
        messageCountLabel.text = messageCount

        // implementation of pause button
        callback = complete

        self.layoutIfNeeded()
    }
}
