//
//  MultiRowsTagsView.swift
//  ProtonMail
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
        rows.enumerated().forEach { rowIndex, row in
            let isFirstRow = rowIndex == 0
            let isLastRow = rowIndex == (rows.count - 1)

            row.enumerated().forEach { itemIndex, item in
                addSubview(item)
                let isFirstItemInRow = itemIndex == 0
                let isLastItemInRow = itemIndex == (row.count - 1)

                if isFirstItemInRow {
                    [item.leadingAnchor.constraint(equalTo: leadingAnchor)].activate()
                } else {
                    if let previousItem = row[safe: itemIndex - 1] {
                        [
                            item.leadingAnchor.constraint(equalTo: previousItem.trailingAnchor,
                                                          constant: horizontalSpacing),
                            item.heightAnchor.constraint(equalTo: previousItem.heightAnchor)
                        ].activate()
                    }
                }

                if isFirstRow {
                    [item.topAnchor.constraint(equalTo: topAnchor)].activate()
                } else {
                    if let previousRowItem = rows[safe: rowIndex - 1]?.last {
                        [
                            item.topAnchor.constraint(equalTo: previousRowItem.bottomAnchor,
                                                      constant: verticalSpacing)
                        ].activate()
                    }
                }

                if isLastItemInRow {
                    [item.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)].activate()
                }

                if isLastItemInRow && isLastRow {
                    [item.bottomAnchor.constraint(equalTo: bottomAnchor)].activate()
                }

                [item.heightAnchor.constraint(equalToConstant: 18.33)].activate()
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
