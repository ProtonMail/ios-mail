//
//  SingleRowTagsView.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import PMUIFoundations
import UIKit

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
        var row = builtViews()
        let containerMax = frame.width
        var rowWidth: CGFloat = 0

        row.enumerated().forEach { index, item in
            let isFirst = index == 0
            let size = item.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            var frame = CGRect(origin: .zero, size: size)

            if isFirst {
                frame.origin.x = 0
            } else {
                let previousItem = row[safe: index - 1]
                frame.origin.x = (previousItem?.frame.maxX ?? 0) + horizontalSpacing
            }

            rowWidth += size.width + horizontalSpacing

            if rowWidth >= containerMax {
                frame.size.width -= (rowWidth - containerMax - horizontalSpacing)
            }

            item.frame = frame
        }

        row = addLabelWithNumberIfNeeded(row: row, rowWidth: rowWidth)
        row.forEach(addSubview)
    }

    private func addLabelWithNumberIfNeeded(row: [UIView], rowWidth: CGFloat) -> [UIView] {
        guard tagViews.count > row.count else { return row }
        var row = row
        let containerWidth = frame.width
        let numberLabel = UILabel()
        numberLabel.attributedText = "+\(tagViews.count - row.count)"
            .apply(style: FontManager.OverlineRegularTextWeak)
        let size = numberLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        var frame = CGRect(origin: .zero, size: size)
        var previousItem = row[safe: row.count - 1]
        let isSingleLongTag = row.count == 1
        if isSingleLongTag {
            previousItem?.frame.size.width -= (horizontalSpacing + size.width)
            frame.origin.x = (previousItem?.frame.maxX ?? 0) + horizontalSpacing
        } else {
            let doesLabelFitRow = rowWidth + size.width <= containerWidth

            if doesLabelFitRow {
                frame.origin.x = (previousItem?.frame.maxX ?? 0) + horizontalSpacing
            } else {
                row.removeLastSafe()
                previousItem = row[safe: row.count - 1]
                numberLabel.attributedText = "+\(tagViews.count - row.count)"
                    .apply(style: FontManager.OverlineRegularTextWeak)
                frame.size = numberLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                frame.origin.x = (previousItem?.frame.maxX ?? 0) + horizontalSpacing
            }
        }

        frame.size.height = self.frame.height

        numberLabel.frame = frame
        return row + [numberLabel]
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
