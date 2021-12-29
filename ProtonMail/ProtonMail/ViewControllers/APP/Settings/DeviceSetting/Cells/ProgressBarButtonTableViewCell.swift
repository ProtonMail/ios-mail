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
    
    typealias buttonActionBlock = () -> Void
    var callback: buttonActionBlock?

    override func awakeFromNib() {
        super.awakeFromNib()

        let parentView: UIView = self.contentView

        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.textColor = ColorProvider.TextNorm
        self.titleLabel.font = UIFont.systemFont(ofSize: 17)
        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 12),
            self.titleLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.titleLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16)
        ])

        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        self.progressView.progressTintColor = ColorProvider.BrandNorm
        NSLayoutConstraint.activate([
            self.progressView.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 24),
            self.progressView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.progressView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16),
            //self.progressView.widthAnchor.constraint(equalToConstant: 343),
            //self.progressView.heightAnchor.constraint(equalToConstant: 8)
        ])

        self.estimatedTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.estimatedTimeLabel.textColor = ColorProvider.TextWeak
        self.estimatedTimeLabel.font = UIFont.systemFont(ofSize: 13)
        NSLayoutConstraint.activate([
            self.estimatedTimeLabel.topAnchor.constraint(equalTo: self.progressView.bottomAnchor, constant: 8),
            self.estimatedTimeLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.estimatedTimeLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16)
        ])

        self.currentProgressLabel.translatesAutoresizingMaskIntoConstraints = false
        self.currentProgressLabel.textAlignment = .right
        self.currentProgressLabel.textColor = ColorProvider.TextWeak
        self.currentProgressLabel.font = UIFont.systemFont(ofSize: 13)
        NSLayoutConstraint.activate([
            self.currentProgressLabel.topAnchor.constraint(equalTo: self.progressView.bottomAnchor, constant: 8),
            self.currentProgressLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.currentProgressLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16)
        ])

        self.pauseButton.titleLabel?.adjustsFontSizeToFitWidth = false
        self.pauseButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        self.pauseButton.setTitleColor(ColorProvider.TextNorm, for: .normal)
        self.pauseButton.backgroundColor = ColorProvider.InteractionWeak
        self.pauseButton.layer.cornerRadius = 8
        self.pauseButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.pauseButton.topAnchor.constraint(equalTo: self.estimatedTimeLabel.bottomAnchor, constant: 16),
            self.pauseButton.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.pauseButton.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -290),
            self.pauseButton.widthAnchor.constraint(equalToConstant: 69),
            self.pauseButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        //status label is hidden by default
        self.statusLabel.translatesAutoresizingMaskIntoConstraints = false
        //self.statusLabel.textAlignment = .left
        //self.statusLabel.isHidden = true
        self.statusLabel.textColor = ColorProvider.TextWeak
        self.statusLabel.font = UIFont.systemFont(ofSize: 13)
        NSLayoutConstraint.activate([
            self.statusLabel.topAnchor.constraint(equalTo: self.estimatedTimeLabel.bottomAnchor, constant: 16),
            self.statusLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.statusLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16)
        ])
    }
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var estimatedTimeLabel: UILabel!
    @IBOutlet weak var currentProgressLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    
    @IBAction func pauseButtonPressed(_ sender: UIButton) {
        callback?()
        self.layoutIfNeeded()
    }
    
    func configCell(_ titleLine: String, _ advice: String, _ estimatedTime: String, _ currentProgress: Int, _ buttonTitle: String, complete: buttonActionBlock?) {
        titleLabel.text = titleLine
        statusLabel.text = advice
        estimatedTimeLabel.text = estimatedTime
        currentProgressLabel.text = String(currentProgress) + "%"
        progressView.setProgress(Float(currentProgress)/100.0, animated: true)
        
        self.pauseButton.setTitle(buttonTitle, for: UIControl.State.normal)

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
