//
//  SettingsGeneralCell.swift
//  Proton Mail - Created on 3/17/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_Foundations
import ProtonCore_UIFoundations
import UIKit

/**
 settings cell
 -------------------------
 | left             right |
 -------------------------
**/

@IBDesignable
class SettingsGeneralCell: UITableViewCell, AccessibleCell {
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var stackViewTrailingConstraintWithIconView: NSLayoutConstraint!
    @IBOutlet private weak var stackViewTrailingConstraintWithContainer: NSLayoutConstraint!
    @IBOutlet private weak var leftText: UILabel!
    @IBOutlet private weak var rightText: UILabel!
    @IBOutlet private weak var rightArrowImage: UIImageView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    enum ImageType {
        case arrow
        case system
        case activityIndicator
        case none
    }

    enum ContentType {
        case informational
        case destructive
    }

    static var CellID: String {
        return "\(self)"
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.rightArrowImage?.tintColor = ColorProvider.TextHint
        rightText.set(text: nil,
                      preferredFont: .body,
                      weight: .regular,
                      textColor: ColorProvider.TextHint)
        rightText.textAlignment = .right
        leftText.set(text: nil,
                     preferredFont: .body,
                     weight: .regular)
        leftText.textAlignment = .left
        leftText.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        leftText.text = nil
        rightText.text = nil
        rightArrowImage.image = nil
        rightArrowImage.isHidden = false
        stackView.distribution = .equalSpacing
        // Because switching from required (>=1000) to non required (<1000) or vice versa causes a crash on iOS 12
        stackViewTrailingConstraintWithIconView.priority = .init(999)
        stackViewTrailingConstraintWithContainer.priority = .defaultLow
    }

    func configureCell(left: String?, right: String?, imageType: ImageType, contentType: ContentType = .informational) {
        if let left = left {
            leftText.text = left
            if contentType == .destructive {
                leftText.textColor = ColorProvider.NotificationError
            } else {
                leftText.textColor = ColorProvider.TextNorm
            }
        }
        if let right = right {
            rightText.text = right
            stackView.distribution = .equalSpacing
        } else {
            stackView.distribution = .fillProportionally
        }

        switch imageType {
        case .arrow, .system:
            self.activityIndicator.isHidden = true
            self.rightArrowImage.image = imageType.image
        case .activityIndicator:
            self.activityIndicator.isHidden = false
            self.rightArrowImage.isHidden = true
            self.activityIndicator.startAnimating()
        case .none:
            self.activityIndicator.isHidden = true
            self.rightArrowImage.isHidden = true
            stackViewTrailingConstraintWithIconView.priority = .defaultLow
            // Because switching from required (>=1000) to non required (<1000) or vice versa causes a crash on iOS 12
            stackViewTrailingConstraintWithContainer.priority = .init(999)
        }
        self.accessibilityLabel = left
        if let text = leftText.text {
            generateCellAccessibilityIdentifiers(text)
        }
    }

    func configure(left: String, imageType: ImageType = .arrow) {
        configureCell(left: left, right: nil, imageType: imageType)
    }

    func configure(right: String, imageType: ImageType = .arrow) {
        configureCell(left: nil, right: right, imageType: imageType)
    }
}

private extension SettingsGeneralCell.ImageType {
    var image: UIImage? {
        switch self {
        case .arrow:
            return IconProvider.chevronRight
        case .system:
            return IconProvider.arrowOutSquare
        case .none, .activityIndicator:
            return nil
        }
    }
}

// MARK: - UI test
extension SettingsGeneralCell {
    func leftTextValue() -> String? {
        leftText.attributedText?.string
    }
}
