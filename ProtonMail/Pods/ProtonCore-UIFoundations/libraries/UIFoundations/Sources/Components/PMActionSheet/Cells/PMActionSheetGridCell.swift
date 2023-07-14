//
//  PMActionSheetGridCell.swift
//  ProtonCore-UIFoundations-iOS - Created on 2023/1/21.
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

final class PMActionSheetGridCell: UICollectionViewCell {
    private var container = UIView(frame: .zero)

    override func prepareForReuse() {
        super.prepareForReuse()
        container.subviews.forEach { $0.removeFromSuperview() }
    }

    private func setUpContainerIfNeeded() {
        guard container.superview == nil else { return }
        contentView.addSubview(container)
        container.fillSuperview()
        container.roundCorner(PMActionSheetConfig.shared.gridRoundCorner)
        container.layer.borderColor = PMActionSheetConfig.shared.gridBorderColor.cgColor
        container.layer.borderWidth = 1
    }

    func config(indexPath: IndexPath, components: [any PMActionSheetComponent]) {
        container.backgroundColor = PMActionSheetConfig.shared.plainCellBackgroundColor
        setUpContainerIfNeeded()
        setUpAccessibility(indexPath: indexPath, components: components)
        let defaultTopPadding: CGFloat = 14
        let defaultBottomPadding: CGFloat = 11
        let defaultLeftPadding: CGFloat = 8
        for (index, component) in components.enumerated() {
            let element = component.makeElement()
            let previousRef = container.subviews.last?.bottomAnchor ?? container.topAnchor
            container.addSubview(element)
            let horizontalOffset = component.offset?.horizontal ?? 0
            element.centerXAnchor
                .constraint(equalTo: container.centerXAnchor, constant: horizontalOffset)
                .isActive = true
            let top = component.edge[0] ?? defaultTopPadding
            element.topAnchor
                .constraint(equalTo: previousRef, constant: top)
                .isActive = true

            let isLastOne = index == components.count - 1
            if isLastOne {
                let bottom = component.edge[2] ?? defaultBottomPadding
                element.bottomAnchor
                    .constraint(equalTo: container.bottomAnchor, constant: -1 * abs(bottom))
                    .isActive = true
            }

            if element is UILabel {
                NSLayoutConstraint.activate([
                    element.leadingAnchor
                        .constraint(
                            greaterThanOrEqualTo: container.leadingAnchor,
                            constant: defaultLeftPadding
                        ).prioritised(as: .defaultLow),
                    element.trailingAnchor
                        .constraint(
                            lessThanOrEqualTo: container.trailingAnchor,
                            constant: -1 * defaultLeftPadding
                        ).prioritised(as: .defaultLow)
                ])
            }
        }
        contentView.setNeedsLayout()
    }

    private func setUpAccessibility(indexPath: IndexPath, components: [any PMActionSheetComponent]) {
        accessibilityIdentifier = "itemIndex_\(indexPath.section).\(indexPath.row)"
        guard let index = components.firstIndex(where: { $0 is PMActionSheetTextComponent }),
              let component = components[safeIndex: index] as? PMActionSheetTextComponent else {
            return
        }
        switch component.text {
        case .left(let text):
            accessibilityLabel = text
        case .right(let attributedText):
            accessibilityLabel = attributedText.string
        }
    }
}

#endif
