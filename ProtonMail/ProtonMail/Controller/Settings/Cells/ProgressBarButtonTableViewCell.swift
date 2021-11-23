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
        
        self.pauseButton.setTitle(LocalString._encrypted_search_pause_button, for: UIControl.State.normal)
        self.pauseButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        self.pauseButton.setTitleColor(ColorProvider.TextNorm, for: .normal)
        self.pauseButton.translatesAutoresizingMaskIntoConstraints = false
        self.pauseButton.backgroundColor = UIColor(hex: 0xEAE7E4, alpha: 1) //TODO replace with ColorProvider
        self.pauseButton.layer.cornerRadius = 8
        NSLayoutConstraint.activate([
            self.pauseButton.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 108),
            self.pauseButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -16),
            self.pauseButton.widthAnchor.constraint(equalToConstant: 69),
            self.pauseButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.progressView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 60),
            self.progressView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -88),
            self.progressView.widthAnchor.constraint(equalToConstant: 343),
            self.progressView.heightAnchor.constraint(equalToConstant: 8)
        ])
        
        self.estimatedTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.estimatedTimeLabel.text = LocalString._encrypted_search_default_text_estimated_time_label
        
        NSLayoutConstraint.activate([
            self.estimatedTimeLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 76),
            self.estimatedTimeLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -64),
            self.estimatedTimeLabel.widthAnchor.constraint(equalToConstant: 343),
            self.estimatedTimeLabel.heightAnchor.constraint(equalToConstant: 16)
        ])

        self.currentProgressLabel.translatesAutoresizingMaskIntoConstraints = false
        self.currentProgressLabel.textAlignment = .right
        NSLayoutConstraint.activate([
            self.currentProgressLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 76),
            self.currentProgressLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -64),
            self.currentProgressLabel.widthAnchor.constraint(equalToConstant: 343),
            self.currentProgressLabel.heightAnchor.constraint(equalToConstant: 16)
        ])

        //status label is hidden by default
        self.statusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.statusLabel.textAlignment = .left
        self.statusLabel.isHidden = true
        NSLayoutConstraint.activate([
            self.statusLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 108),
            self.statusLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -16),
            self.statusLabel.widthAnchor.constraint(equalToConstant: 343),
            self.statusLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.textColor = ColorProvider.TextNorm
        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 12),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -120),
            self.titleLabel.widthAnchor.constraint(equalToConstant: 289.7),
            self.titleLabel.heightAnchor.constraint(equalToConstant: 24)
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
    
    func configCell(_ titleLine: String, _ status: String, _ estimatedTime: Int, _ currentProgress: Int, complete: buttonActionBlock?) {
        var leftAttributes = FontManager.Default.alignment(.left)
        leftAttributes[.foregroundColor] = ColorProvider.TextNorm
        titleLabel.attributedText = NSMutableAttributedString(string: titleLine, attributes: leftAttributes)
        
        statusLabel.text = status
        estimatedTimeLabel.text = String(estimatedTime) + " minutes remaining..."
        currentProgressLabel.text = String(currentProgress) + "%"
        progressView.setProgress(Float(currentProgress)/100.0, animated: true)
        
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
