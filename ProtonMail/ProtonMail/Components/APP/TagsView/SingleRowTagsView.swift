//
//  SingleRowTagsView.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
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

import UIKit
import ProtonCore_UIFoundations

class SingleRowTagsView: UIView {

    init() {
        super.init(frame: .zero)
    }

    var tagViews: [UIView] = [] {
        didSet { reloadTagsView() }
    }

    var horizontalSpacing: CGFloat = 4 {
        didSet { reloadTagsView() }
    }

    override var intrinsicContentSize: CGSize {
        .init(width: frame.size.width, height: subviews.map { $0.frame.maxY }.max() ?? 0)
    }

    private var size: CGSize?

    override func layoutSubviews() {
        super.layoutSubviews()

        let sizeHasChanged = size != frame.size
        guard sizeHasChanged else { return }
        size = frame.size

        reloadTagsView()
    }

    private func reloadTagsView() {
        subviews.forEach { $0.removeFromSuperview() }
        setUpViews()
        invalidateIntrinsicContentSize()
    }

    private func setUpViews() {
        let row = builtViews()

        row.enumerated().forEach { index, item in
            self.addSubview(item)
            let itemSize = item.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

            let leadingConstrain: NSLayoutConstraint
            if let previousItem = row[safe: index - 1] {
                let trailing = previousItem.trailingAnchor
                leadingConstrain = item.leadingAnchor.constraint(equalTo: trailing, constant: horizontalSpacing)
            } else {
                leadingConstrain = item.leadingAnchor.constraint(equalTo: self.leadingAnchor)
            }

            [
                item.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor),
                item.heightAnchor.constraint(equalToConstant: itemSize.height),
                item.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                leadingConstrain
            ].activate()
            let widthConstraint = item.widthAnchor.constraint(equalToConstant: itemSize.width)
            widthConstraint.priority = .defaultLow
            widthConstraint.isActive = true

            if index == 0 {
                [
                    self.heightAnchor.constraint(equalToConstant: itemSize.height)
                ].activate()
            }
        }
        self.addLabelWithNumberIfNeeded(row: row)
    }

    private func addLabelWithNumberIfNeeded(row: [UIView]) {
        guard tagViews.count > row.count,
              let lastItem = row.last else { return }
        let numberLabel = UILabel()
        self.addSubview(numberLabel)
        [
            numberLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            numberLabel.leadingAnchor.constraint(equalTo: lastItem.trailingAnchor, constant: horizontalSpacing),
            numberLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ].activate()
        numberLabel.set(text: "+\(tagViews.count - row.count)",
                        preferredFont: .caption2,
                        weight: .semibold,
                        textColor: ColorProvider.TextWeak)
        numberLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        numberLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func builtViews() -> [UIView] {
        var row: [UIView] = []
        let containerWidth = frame.width
        var rowWidth: CGFloat = 0
        for tag in tagViews {
            let tagWidth = tag.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width

            if rowWidth + tagWidth <= containerWidth {
                rowWidth += tagWidth + horizontalSpacing
                row.append(tag)
            } else {
                if row.isEmpty {
                    row.append(tag)
                }
                return row
            }
        }

        return row
    }

    required init?(coder: NSCoder) {
        nil
    }

}
