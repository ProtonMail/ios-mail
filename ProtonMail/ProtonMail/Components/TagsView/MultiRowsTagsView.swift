//
//  MultiRowsTagsView.swift
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

import UIKit

class MultiRowsTagsView: UIView {

    init() {
        super.init(frame: .zero)
    }

    var horizontalSpacing: CGFloat = 4 {
        didSet { reloadTagsView() }
    }

    var verticalSpacing: CGFloat = 8 {
        didSet { reloadTagsView() }
    }

    var tagViews: [UIView] = [] {
        didSet { reloadTagsView() }
    }

    override var intrinsicContentSize: CGSize {
        .init(width: frame.size.width, height: subviews.map { $0.frame.maxY }.max() ?? 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        reloadTagsView()
    }

    private func reloadTagsView() {
        subviews.forEach { $0.removeFromSuperview() }
        setUpViews()
        invalidateIntrinsicContentSize()
    }

    private func setUpViews() {
        let rows = builtViews()
        let containerMax = frame.width
        rows.enumerated().forEach { rowIndex, row in
            let isFirstRow = rowIndex == 0

            row.enumerated().forEach { itemIndex, item in
                addSubview(item)
                let isFirstItemInRow = itemIndex == 0
                let size = item.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                var frame = CGRect(origin: .zero, size: size)

                if isFirstItemInRow {
                    frame.origin.x = 0
                } else {
                    let previousItem = row[safe: itemIndex - 1]
                    frame.origin.x = (previousItem?.frame.maxX ?? 0) + horizontalSpacing
                    frame.size.height = (previousItem?.frame.height ?? 0)
                }

                if isFirstRow {
                    frame.origin.y = 0
                } else {
                    let previousRow = rows[safe: rowIndex - 1]
                    frame.origin.y = (previousRow?.last?.frame.maxY ?? 0)
                    frame.origin.y += verticalSpacing
                }

                let sum = frame.origin.x + frame.size.width

                if sum > containerMax {
                    let newSize = frame.size.width - abs(containerMax - sum)
                    frame.size.width = newSize
                }

                item.frame = frame
            }
        }
    }

    private func builtViews() -> [[UIView]] {
        var rows: [[UIView]] = [[]]
        let containerWidth = frame.width
        var rowWidth: CGFloat = 0
        tagViews.forEach { tag in
            let tagWidth = tag.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
            if rowWidth + tagWidth <= containerWidth || rows[rows.endIndex - 1].isEmpty {
                rowWidth += tagWidth + horizontalSpacing
            } else {
                rowWidth = tagWidth + horizontalSpacing
                rows.append([])
            }
            var row = rows[rows.endIndex - 1]
            row.append(tag)
            rows[rows.endIndex - 1] = row
        }
        return rows
    }

    required init?(coder: NSCoder) {
        nil
    }

}
