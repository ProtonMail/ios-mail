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

import ProtonCoreUIFoundations
import SkeletonView
import UIKit

final class ConversationSkeletonCell: UITableViewCell {
    private let container = SubviewsFactory.containerView
    private let initialView = SubviewsFactory.initialView
    private let textView = SubviewsFactory.textView
    private let dateView = SubviewsFactory.dateView
    private let separator = SubviewsFactory.separatorView
    private let bodyView = SubviewsFactory.bodyView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        container.backgroundColor = ColorProvider.BackgroundNorm
        addSubviews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func addSubviews() {
        contentView.addSubview(container)
        container.addSubview(initialView)
        container.addSubview(textView)
        container.addSubview(dateView)
        container.addSubview(separator)
        container.addSubview(bodyView)
    }

    private func setupLayout() {
        [
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ].activate()

        [
            initialView.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            initialView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            initialView.heightAnchor.constraint(equalToConstant: 28),
            initialView.widthAnchor.constraint(equalToConstant: 28),
            textView.leadingAnchor.constraint(equalTo: initialView.trailingAnchor, constant: 12),
            textView.topAnchor.constraint(equalTo: initialView.topAnchor),
            textView.trailingAnchor.constraint(equalTo: dateView.leadingAnchor, constant: -12),
            textView.heightAnchor.constraint(equalToConstant: 84),
            dateView.topAnchor.constraint(equalTo: initialView.topAnchor),
            dateView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            dateView.widthAnchor.constraint(equalToConstant: 120),
            dateView.heightAnchor.constraint(equalToConstant: 16),
            textView.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: -8),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            bodyView.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 16),
            bodyView.heightAnchor.constraint(equalToConstant: 150),
            bodyView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            bodyView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            bodyView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ].activate()
    }
}

private enum SubviewsFactory {
    static var containerView: UIView {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }

    static var initialView: UIView {
        let view = UIView()
        view.isSkeletonable = true
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.showAnimatedGradientSkeleton()
        return view
    }

    static var textView: UITextView {
        let view = UITextView()
        view.linesCornerRadius = 5
        view.lastLineFillPercent = 30
        view.skeletonTextNumberOfLines = 3
        view.isSkeletonable = true
        view.showAnimatedGradientSkeleton()
        return view
    }

    static var dateView: UILabel {
        let view = UILabel()
        view.isSkeletonable = true
        view.linesCornerRadius = 5
        view.skeletonTextNumberOfLines = 1
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        view.showAnimatedGradientSkeleton()
        return view
    }

    static var separatorView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.SeparatorNorm
        return view
    }

    static var bodyView: UITextView {
        let view = UITextView()
        view.linesCornerRadius = 5
        view.lastLineFillPercent = 30
        view.skeletonTextNumberOfLines = 5
        view.isSkeletonable = true
        view.showAnimatedGradientSkeleton()
        return view
    }
}
