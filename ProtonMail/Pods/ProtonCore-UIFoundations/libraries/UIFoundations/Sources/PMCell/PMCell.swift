//
//  HelpItemCell.swift
//  ProtonCore-UIFoundations - Created on 04/11/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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

public final class PMCell: UITableViewCell {

    public static let reuseIdentifier = "PMCell"
    public static let nib = UINib(nibName: "PMCell", bundle: PMUIFoundations.bundle)

    // MARK: - Outlets

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var arrowImageView: UIImageView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var subtitleLabel: UILabel!

    // MARK: - Properties

    public var title: String? {
        didSet {
            guard let title = title else {
                titleLabel.attributedText = nil
                return
            }

            let style = NSMutableParagraphStyle()
            let attrString = NSMutableAttributedString(string: title)
            style.minimumLineHeight = 24
            style.maximumLineHeight = 24
            attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: title.count))
            titleLabel.attributedText = attrString
        }
    }

    public var subtitle: String? {
        didSet {
            guard let subtitle = subtitle else {
                subtitleLabel.attributedText = nil
                subtitleLabel.isHidden = true
                return
            }

            let style = NSMutableParagraphStyle()
            let attrString = NSMutableAttributedString(string: subtitle)
            style.minimumLineHeight = 20
            style.maximumLineHeight = 20
            attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: subtitle.count))
            subtitleLabel.attributedText = attrString
            subtitleLabel.isHidden = false
        }
    }

    public var icon: UIImage? {
        didSet {
            iconImageView.image = icon
        }
    }

    public var showArrow: Bool = true {
        didSet {
            arrowImageView.isHidden = !showArrow
        }
    }

    public var isLoading: Bool = false {
        didSet {
            if isLoading {
                activityIndicator.startAnimating()
                arrowImageView.isHidden = true
            } else {
                activityIndicator.stopAnimating()
                arrowImageView.isHidden = showArrow
            }
        }
    }

    public var isDisabled: Bool = false {
        didSet {
            setStateColors()
        }
    }

    // MARK: - Setup

    override public func awakeFromNib() {
        super.awakeFromNib()

        setStateColors()

        activityIndicator.color = UIColorManager.BrandNorm

        // selection color
        selectionStyle = .gray
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColorManager.Shade10
        selectedBackgroundView = bgColorView
    }

    private func setStateColors() {
        let color = isDisabled ? UIColorManager.TextDisabled : UIColorManager.TextNorm
        titleLabel.textColor = color
        subtitleLabel.textColor = isDisabled ? UIColorManager.TextDisabled : UIColorManager.TextWeak
        iconImageView.tintColor = color
        arrowImageView.image = isDisabled ? UIImage(named: "CellArrowDisabled", in: PMUIFoundations.bundle, compatibleWith: nil) : UIImage(named: "CellArrow", in: PMUIFoundations.bundle, compatibleWith: nil)
    }
}
