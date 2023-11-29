//
//  PMActionSheetPlainCellTableViewCell.swift
//  ProtonCore-UIFoundations-iOS - Created on 2023/1/18.
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
import ProtonCoreFoundations

protocol PMActionSheetPlainCellDelegate: AnyObject {
    func toggleTriggeredAt(indexPath: IndexPath)
}

final class PMActionSheetPlainCell: UITableViewCell, AccessibleView {
    private weak var delegate: PMActionSheetPlainCellDelegate?
    private var container = UIView(frame: .zero)
    private var indexPath: IndexPath = IndexPath(row: -1, section: -1)
    private var totalItemsCount: Int = 0
    private var separator: UIView?

    override func prepareForReuse() {
        super.prepareForReuse()
        container.subviews.forEach { $0.removeFromSuperview() }
        container.layer.mask = nil
        separator?.removeFromSuperview()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        setRoundedCorners(currentRow: indexPath.row, total: totalItemsCount)
    }

    func config(
        item: PMActionSheetItem,
        at indexPath: IndexPath,
        style: PMActionSheetItemGroup.Style,
        totalItemsCount: Int,
        delegate: PMActionSheetPlainCellDelegate?
    ) {
        contentView.backgroundColor = PMActionSheetConfig.shared.actionSheetBackgroundColor
        container.backgroundColor = PMActionSheetConfig.shared.plainCellBackgroundColor
        self.delegate = delegate
        self.indexPath = indexPath
        self.totalItemsCount = totalItemsCount
        selectionStyle = .none
        setUpContainerIfNeeded()
        setUpIndentationIfNeeded(level: item.indentationLevel, width: item.indentationWidth)

        let components = item.components
        for (index, component) in components.enumerated() {
            let hasCheckMark = (style == .singleSelectionNewStyle) || (item.markType != .none)
            let isLastOne = (index == components.count - 1) && !hasCheckMark
            appendComponent(component, isLastOne: isLastOne)
        }
        addMarkIconIfNeeded(markType: item.markType, style: style)

        addSeparator(hasSeparator: item.hasSeparator)
        setUpAccessibility(components: components)
    }

    private func setUpContainerIfNeeded() {
        guard container.superview == nil else { return }
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        let isNewFigmaTheme = PMActionSheetConfig.shared.isNewFigmaTheme
        let padding: CGFloat = isNewFigmaTheme ? 16 : 0
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1 * padding),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding)
        ])
    }

    private func setUpIndentationIfNeeded(level: Int, width: CGFloat) {
        guard level != 0 else { return }
        let block = UIView(frame: .zero)
        block.backgroundColor = .clear
        block.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(block)
        NSLayoutConstraint.activate([
            block.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            block.topAnchor.constraint(equalTo: container.topAnchor),
            block.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            block.widthAnchor.constraint(equalToConstant: width * CGFloat(level))
        ])
    }

    private func appendComponent(_ component: any PMActionSheetComponent, isLastOne: Bool) {
        let element = component.makeElement()
        observeToggleActionIfNeeded(element: element)
        let previousRef = container.subviews.last?.trailingAnchor ?? container.leadingAnchor
        container.addSubview(element)

        let verticalOffset: CGFloat = component.offset?.vertical ?? 0
        element.centerYAnchor
            .constraint(equalTo: container.centerYAnchor, constant: verticalOffset)
            .isActive = true
        if let leftPadding = component.edge[3] {
            element.leadingAnchor
                .constraint(equalTo: previousRef, constant: leftPadding)
                .isActive = true
        }
        if isLastOne {
            let rightPadding = component.edge[1] ?? 16
            _ = element.trailingAnchor
                .constraint(equalTo: container.trailingAnchor, constant: -1 * abs(rightPadding))
                .isActive = true
        }
    }

    private func addMarkIconIfNeeded(
        markType: PMActionSheetItem.MarkType,
        style: PMActionSheetItemGroup.Style
    ) {
        let image: UIImage
        let color: UIColor
        let config = PMActionSheetConfig.shared
        switch style {
        case .singleSelectionNewStyle, .multiSelectionNewStyle:
            guard let icon = markType.iconNewStyle else { return }
            image = icon
            color = markType == .none ? config.checkMarkUnSelectedColor : config.checkMarkSelectedColor
        case .multiSelection, .singleSelection:
            guard markType != .none,
                  let icon = markType.icon else { return }
            image = icon
            color = config.checkMarkSelectedColor
        case .clickable, .toggle, .grid:
            return
        }
        let context = PMActionSheetIconComponent(
            icon: image,
            iconColor: color,
            edge: [nil, 16, nil, 8]
        )
        appendComponent(context, isLastOne: true)
    }

    private func observeToggleActionIfNeeded(element: UIView) {
        guard let toggle = element as? UISwitch else { return }
        toggle.addTarget(self, action: #selector(self.triggerToggle), for: .valueChanged)
    }

    private func setUpAccessibility(components: [any PMActionSheetComponent]) {
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

    private func setRoundedCorners(currentRow: Int, total: Int) {
        guard PMActionSheetConfig.shared.isNewFigmaTheme else { return }
        let radius = PMActionSheetConfig.shared.actionSheetRadius
        let size = CGSize(width: radius, height: radius)
        if currentRow == 0 {
            let path = UIBezierPath(roundedRect: container.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: size)
            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            container.layer.mask = maskLayer
        } else if currentRow == total - 1 {
            let path = UIBezierPath(roundedRect: container.bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: size)
            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            container.layer.mask = maskLayer
        }
    }

    func addSeparator(hasSeparator: Bool) {
        let isNewFigmaStyle = PMActionSheetConfig.shared.isNewFigmaTheme
        if isNewFigmaStyle || !hasSeparator {
            // In new style, last item doesn't have separator
            return
        }
        let line = UIView()
        container.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        let ref = container.subviews.first(where: { $0 is UILabel })?.leadingAnchor ?? container.leadingAnchor
        let refAnchor = isNewFigmaStyle ? ref : container.leadingAnchor
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: refAnchor),
            line.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
            line.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1)
        ])
        line.backgroundColor = ColorProvider.SeparatorNorm
        separator = line
    }

    @objc
    private func triggerToggle() {
        delegate?.toggleTriggeredAt(indexPath: indexPath)
    }
}

#endif
