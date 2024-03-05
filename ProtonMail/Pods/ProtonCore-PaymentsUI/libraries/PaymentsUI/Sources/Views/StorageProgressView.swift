//
//  StorageProgressView.swift
//  ProtonCorePaymentsUI - Created on 24/02/2022.
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

#if os(iOS)

import UIKit
import ProtonCoreUIFoundations
import ProtonCoreFoundations
import ProtonCoreFeatureFlags

final class StorageProgressView: UIView, AccessibleCell {

    private let warningPercentage = 0.5
    private let alertPercentage = 0.8
    static let reuseIdentifier = "StorageProgressView"
    static let nib = UINib(nibName: "StorageProgressView", bundle: PaymentsUI.bundle)

    // MARK: - Outlets

    @IBOutlet var mainView: UIView! {
        didSet {
            mainView.frame = bounds
            mainView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            mainView.backgroundColor = .clear
        }
    }
    @IBOutlet weak var titleLabel: UILabel!{
        didSet {
            titleLabel.backgroundColor = .clear
            titleLabel.textColor = ColorProvider.TextNorm
        }
    }
    @IBOutlet weak var statusIconView: UIImageView!
    @IBOutlet weak var storageLabel: UILabel! {
        didSet {
            storageLabel.backgroundColor = .clear
            storageLabel.textColor = ColorProvider.TextNorm
        }
    }
    @IBOutlet weak var backgroundProgressView: UIView! {
        didSet {
            backgroundProgressView.layer.cornerRadius = backgroundProgressView.bounds.height / 2
            backgroundProgressView.backgroundColor = ColorProvider.SeparatorNorm
        }
    }
    var progressView: UIView?

    override func layoutSubviews() {
        super.layoutSubviews()

        // Mask the `progressView` to keep rounded corners at the ends of the progress bar.
        let maskLayer = CALayer()
        maskLayer.frame = backgroundProgressView.bounds
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.cornerRadius = backgroundProgressView.layer.cornerRadius
        progressView?.layer.mask = maskLayer
    }

    // MARK: - Properties

    override init(frame: CGRect) {
        super.init(frame: frame)
        load()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        load()
    }

    private func load() {
        PaymentsUI.bundle.loadNibNamed(StorageProgressView.reuseIdentifier, owner: self, options: nil)
        addSubview(mainView)
        backgroundColor = .clear
        let progressView = UIView()
        mainView.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: backgroundProgressView.leadingAnchor),
            progressView.topAnchor.constraint(equalTo: backgroundProgressView.topAnchor),
            progressView.bottomAnchor.constraint(equalTo: backgroundProgressView.bottomAnchor)
        ])
        self.progressView = progressView
        storageLabel.font = .adjustedFont(forTextStyle: .footnote, fontSize: 14)
        titleLabel.font = .adjustedFont(forTextStyle: .footnote, fontSize: 14)
    }

    func configure(title: String? = nil, iconUrl: URL? = nil, usedSpaceDescription: String, usedSpace: Int64, maxSpace: Int64) {
        let factor = CGFloat(usedSpace) / CGFloat(maxSpace)
        // avoid showing empty progress bar
        let multiplier = factor < 0.01 ? 0.01 : factor
        guard multiplier <= 1.0 else { return }
        progressView?.widthAnchor.constraint(equalTo: backgroundProgressView.widthAnchor, multiplier: multiplier).isActive = true
        progressView?.backgroundColor = getColor(multiplier: multiplier)

        if FeatureFlagsRepository.shared.isEnabled(CoreFeatureFlagType.splitStorage), let title = title {
            titleLabel.text = title
            storageLabel.text = usedSpaceDescription
            storageLabel.textColor = getLabelColor(multiplier: multiplier)
            statusIconView.tintColor = iconColor()
            setStatusIcon(with: iconUrl)
        } else {
            titleLabel.text = usedSpaceDescription
            storageLabel.text = ""
            statusIconView.image = nil
        }
    }

    private func getColor(multiplier: CGFloat) -> UIColor {
        if multiplier <= warningPercentage {
            return ColorProvider.NotificationSuccess
        } else if multiplier <= alertPercentage {
            return ColorProvider.NotificationWarning
        } else {
            return ColorProvider.NotificationError
        }
    }

    private func getLabelColor(multiplier: CGFloat) -> UIColor {
        if multiplier > alertPercentage {
            return ColorProvider.NotificationError
        } else {
            return ColorProvider.TextNorm
        }
    }

    private func iconColor() -> UIColor {
        ColorProvider.NotificationError
    }

    private func setStatusIcon(with iconUrl: URL? = nil) {
        statusIconView.sd_setImage(with: iconUrl) { [weak self] image, error, cacheType, url in
            guard error == nil else {
                self?.statusIconView.image = nil
                return
            }

            self?.statusIconView.image = self?.statusIconView.image?.withRenderingMode(.alwaysTemplate)
        }
    }
}

#endif
