//
//  StorageProgressView.swift
//  ProtonCore_PaymentsUI - Created on 24/02/2022.
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
import ProtonCore_Foundations

final class StorageProgressView: UIView, AccessibleCell {

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
    }
    
    func configure(usedSpaceDescription: String, usedSpace: Int64, maxSpace: Int64) {
        storageLabel.text = usedSpaceDescription
        let factor = CGFloat(usedSpace) / CGFloat(maxSpace)
        // avoid showing empty progress bar
        let multiplier = factor < 0.01 ? 0.01 : factor
        guard multiplier <= 1.0 else { return }
        progressView?.widthAnchor.constraint(equalTo: backgroundProgressView.widthAnchor, multiplier: multiplier).isActive = true
        progressView?.backgroundColor = getColor(multiplier: multiplier)
    }
    
    private func getColor(multiplier: CGFloat) -> UIColor {
        if multiplier <= 0.5 {
            return ColorProvider.NotificationSuccess
        } else if multiplier <= 0.9 {
            return ColorProvider.NotificationWarning
        } else {
            return ColorProvider.NotificationError
        }
    }
}
