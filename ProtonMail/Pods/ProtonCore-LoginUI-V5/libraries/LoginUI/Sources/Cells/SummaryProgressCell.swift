//
//  SummaryProgressCell.swift
//  ProtonCore-Login - Created on 10/09/2021.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_UIFoundations

final class SummaryProgressCell: UITableViewCell {

    static let reuseIdentifier = "SummaryProgressCell"

    // MARK: - Outlets

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.transform = CGAffineTransform(scaleX: 0.65, y: 0.65)
        }
    }
    @IBOutlet private weak var stepImageView: UIImageView!
    @IBOutlet private weak var stepLabel: UILabel!
    @IBOutlet weak var labelLeadingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        stepLabel.font = .adjustedFont(forTextStyle: .subheadline)
    }
    
    // MARK: - Properties

    func configureCell(displayProgress: DisplayProgress) {
        backgroundColor = ColorProvider.BackgroundNorm
        if displayProgress.state == .waiting {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        stepImageView?.image = displayProgress.state.image
        stepImageView?.tintColor = ColorProvider.InteractionNorm
        stepLabel.text = displayProgress.step.localizedString
        stepLabel.textColor = displayProgress.state == .initial ? ColorProvider.TextDisabled : ColorProvider.TextNorm
        activityIndicator.color = ColorProvider.BrandNorm
    }
    
    var getWidth: CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: stepLabel.font]
        let size = stepLabel.text?.size(withAttributes: fontAttributes as [NSAttributedString.Key: Any])
        return (size?.width ?? 0) + labelLeadingConstraint.constant + 1
    }
}
