// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

final class DownloadMessagesProgressView: UIView {
    private let labelAboveProgress = SubviewFactory.label
    private let progressView = SubviewFactory.progressView
    private let labelBelowProgress = SubviewFactory.label
    private let progressPercentage = SubviewFactory.label

    private let regularColor: UIColor = ColorProvider.TextWeak
    private let errorColor: UIColor = ColorProvider.NotificationError

    init() {
        super.init(frame: .zero)
        setUpView()
        setUpConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpView() {
        [labelAboveProgress, progressView, labelBelowProgress, progressPercentage].forEach {
            addSubview($0)
        }
    }

    private func setUpConstraints() {
        let verticalSpacing = 8.0
        [
            labelAboveProgress.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelAboveProgress.topAnchor.constraint(equalTo: topAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.topAnchor.constraint(equalTo: labelAboveProgress.bottomAnchor, constant: verticalSpacing),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelBelowProgress.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelBelowProgress.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: verticalSpacing),
            progressPercentage.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressPercentage.centerYAnchor.constraint(equalTo: labelBelowProgress.centerYAnchor),
            bottomAnchor.constraint(equalTo: labelBelowProgress.bottomAnchor)
        ].activate()
    }

    func set(aboveText: String) {
        labelAboveProgress.text = aboveText
    }

    func set(belowText: String, useErrorColor: Bool = false) {
        labelBelowProgress.text = belowText
        labelBelowProgress.textColor = useErrorColor ? errorColor : regularColor
    }

    func set(progressPercentage percentage: Int, useErrorColor: Bool = false) {
        progressPercentage.text = percentage.toPercentFormatString
        progressPercentage.textColor = useErrorColor ? errorColor : regularColor
        let value = min(max(Float(percentage) / 100.0, 0.0), 1.0)
        progressView.setProgress(value, animated: false)
    }

    private enum SubviewFactory {
        static var progressView: UIProgressView {
            let progressView = UIProgressView()
            progressView.translatesAutoresizingMaskIntoConstraints = false
            progressView.progressTintColor = ColorProvider.BrandNorm
            return progressView
        }

        static var label: UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .adjustedFont(forTextStyle: .footnote)
            label.adjustsFontForContentSizeCategory = true
            return label
        }
    }
}
