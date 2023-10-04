//
//  PMActionSheetHeaderView.swift
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
import enum ProtonCoreUtilities.Either

public final class PMActionSheetHeaderView: UIView, AccessibleView {
    private var leftItem: PMActionSheetButtonComponent?
    private var rightItem: PMActionSheetButtonComponent?
    private var titleItem: PMActionSheetItem?
    private var subtitleItem: PMActionSheetItem?
    private var itemView: UIView = UIView(frame: .zero)
    private var leftItemHandler: (() -> Void)?
    private var rightItemHandler: (() -> Void)?

    public convenience init(
        titleItem: PMActionSheetItem?,
        subtitleItem: PMActionSheetItem?,
        leftItem: PMActionSheetButtonComponent?,
        rightItem: PMActionSheetButtonComponent?,
        showDragBar: Bool = true,
        hasSeparator: Bool = false,
        leftItemHandler: (() -> Void)?,
        rightItemHandler: (() -> Void)?
    ) {
        self.init(frame: .zero)
        self.leftItem = leftItem
        self.rightItem = rightItem
        self.titleItem = titleItem
        self.subtitleItem = subtitleItem
        self.leftItemHandler = leftItemHandler
        self.rightItemHandler = rightItemHandler

        self.setup(hasSeparator: hasSeparator, showDragBar: showDragBar)
        generateAccessibilityIdentifiers()
    }

    public convenience init(
        title: String?,
        subtitle: String? = nil,
        leftItem: Either<String, UIImage>? = nil,
        rightItem: Either<String, UIImage>? = nil,
        showDragBar: Bool = true,
        hasSeparator: Bool = false,
        leftItemHandler: (() -> Void)? = nil,
        rightItemHandler: (() -> Void)? = nil
    ) {
        let config = PMActionSheetConfig.shared
        var subtitleItem: PMActionSheetItem?
        if let subtitle {
            subtitleItem = PMActionSheetItem(components: [
                PMActionSheetTextComponent(
                    text: .left(subtitle),
                    textColor: config.headerViewSubtitleTextColor,
                    edge: [nil, nil, nil, nil],
                    font: config.headerViewSubtitleFont
                )
            ], handler: nil)
        }
        var titleItem: PMActionSheetItem?
        if let title {
            let font = subtitle == nil ? config.headerViewTitleFontWOSubtitle : config.headerViewTitleFontWithSubtitle
            titleItem = PMActionSheetItem(components: [
                PMActionSheetTextComponent(
                    text: .left(title),
                    edge: [nil, nil, nil, nil],
                    font: font
                )
            ], handler: nil)
        }
        let leftButton = PMActionSheetHeaderView.makeButtonComponent(item: leftItem, isLeftItem: true)
        let rightButton = PMActionSheetHeaderView.makeButtonComponent(item: rightItem, isLeftItem: false)
        self.init(
            titleItem: titleItem,
            subtitleItem: subtitleItem,
            leftItem: leftButton,
            rightItem: rightButton,
            showDragBar: showDragBar,
            hasSeparator: hasSeparator,
            leftItemHandler: leftItemHandler,
            rightItemHandler: rightItemHandler
        )
    }

    @available(*, deprecated, message: "this will be removed. use other initialize function instead")
    public convenience init(
        title: String,
        subtitle: String?,
        leftItem: PMActionSheetPlainItem?,
        rightItem: PMActionSheetPlainItem?,
        leftTitleViews: [UIView] = [],
        rightTitleViews: [UIView] = [],
        showDragBar: Bool,
        hasSeparator: Bool = false,
        leftItemHandler: (() -> Void)?,
        rightItemHandler: (() -> Void)?
    ) {
        let config = PMActionSheetConfig.shared
        var subtitleItem: PMActionSheetItem?
        if let subtitle {
            subtitleItem = PMActionSheetItem(components: [
                PMActionSheetTextComponent(
                    text: .left(subtitle),
                    textColor: config.headerViewSubtitleTextColor,
                    edge: [nil, nil, nil, nil],
                    font: config.headerViewSubtitleFont
                )
            ], handler: nil)
        }
        let font = subtitle == nil ? config.headerViewTitleFontWOSubtitle : config.headerViewTitleFontWithSubtitle
        let titleItem = PMActionSheetItem(
            components: [
                PMActionSheetTextComponent(
                    text: .left(title),
                    edge: [nil, nil, nil, nil],
                    font: font
                )
            ],
            handler: nil
        )

        var leftButton: PMActionSheetButtonComponent?
        if let leftItem {
            if let title = leftItem.title {
                leftButton = PMActionSheetHeaderView.makeButtonComponent(item: .left(title), isLeftItem: true)
            } else if let icon = leftItem.icon {
                leftButton = PMActionSheetHeaderView.makeButtonComponent(item: .right(icon), isLeftItem: true)
            }
        }
        var rightButton: PMActionSheetButtonComponent?
        if let rightItem {
            if let title = rightItem.title {
                rightButton = PMActionSheetHeaderView.makeButtonComponent(item: .left(title), isLeftItem: false)
            } else if let icon = rightItem.icon {
                rightButton = PMActionSheetHeaderView.makeButtonComponent(item: .right(icon), isLeftItem: false)
            }
        }

        self.init(
            titleItem: titleItem,
            subtitleItem: subtitleItem,
            leftItem: leftButton,
            rightItem: rightButton,
            showDragBar: showDragBar,
            hasSeparator: hasSeparator,
            leftItemHandler: leftItemHandler,
            rightItemHandler: rightItemHandler
        )
    }

    class func makeButtonComponent(item: Either<String, UIImage>?, isLeftItem: Bool) -> PMActionSheetButtonComponent? {
        guard let item = item else { return nil }
        let color: UIColor
        let edge: [CGFloat?]
        var size: CGSize?
        switch item {
        case .left:
            color = PMActionSheetConfig.shared.headerViewItemTextColor
            edge = isLeftItem ? [nil, nil, nil, 16] : [nil, 16, nil, nil]
        case .right:
            color = PMActionSheetConfig.shared.headerViewItemIconColor
            edge = isLeftItem ? [nil, nil, nil, 8] : [nil, 8, nil, nil]
            size = PMActionSheetConfig.shared.headerViewItemIconSize
        }
        return PMActionSheetButtonComponent(
            content: item,
            color: color,
            size: size,
            edge: edge
        )
    }

    override private init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(iOS, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

extension PMActionSheetHeaderView {
    private func setup(hasSeparator: Bool = false, showDragBar: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = PMActionSheetConfig.shared.actionSheetBackgroundColor
        setUpItemView()
        let leftElement = setUpItem(component: leftItem, isLeftItem: true)
        let rightElement = setUpItem(component: rightItem, isLeftItem: false)
        let stackView = setUpStackView()

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: itemView.topAnchor, constant: 4),
            stackView.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -4)
        ])
        setUpStackViewHorizontalConstraint(stackView: stackView, leftElement: leftElement, rightElement: rightElement)
        if hasSeparator {
            addLine()
        }
        if showDragBar {
            addDragBar()
        }
    }

    private func setUpItemView() {
        itemView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(itemView)
        NSLayoutConstraint.activate([
            itemView.leadingAnchor.constraint(equalTo: leadingAnchor),
            itemView.topAnchor.constraint(equalTo: topAnchor, constant: 22),
            itemView.trailingAnchor.constraint(equalTo: trailingAnchor),
            itemView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            itemView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func setUpItem(component: PMActionSheetButtonComponent?, isLeftItem: Bool) -> UIView? {
        guard let component = component else { return nil }
        let element = component.makeElement()
        itemView.addSubview(element)
        let verticalOffset = component.offset?.vertical ?? 0
        element.centerYAnchor.constraint(equalTo: itemView.centerYAnchor, constant: verticalOffset).isActive = true
        if isLeftItem {
            let constant = component.edge[3] ?? 16
            element.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: constant).isActive = true
            element.addTarget(self, action: #selector(self.clickLeftItem), for: .touchUpInside)
        } else {
            let constant = component.edge[1] ?? 16
            element.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -1 * abs(constant)).isActive = true
            element.addTarget(self, action: #selector(self.clickRightItem), for: .touchUpInside)
        }
        element.layoutIfNeeded()
        return element
    }

    private func addSpacer(onLeftSide: Bool, refElement: UIView, component: PMActionSheetButtonComponent?) -> UIView {
        let spacer = UIView(frame: .zero)
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.backgroundColor = .clear
        itemView.addSubview(spacer)
        NSLayoutConstraint.activate([
            spacer.widthAnchor.constraint(equalTo: refElement.widthAnchor),
            spacer.heightAnchor.constraint(equalTo: refElement.heightAnchor),
            spacer.centerYAnchor.constraint(equalTo: itemView.centerYAnchor)
        ])
        if onLeftSide {
            let constant = component?.edge[1] ?? 16
            spacer.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: abs(constant)).isActive = true
        } else {
            let constant = component?.edge[3] ?? 16
            spacer.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -1 * abs(constant)).isActive = true
        }
        return spacer
    }

    private func setUpStackView() -> UIStackView {
        let titleElement = setUpTitleItem(item: titleItem)
        let subtitleElement = setUpTitleItem(item: subtitleItem)
        let stack = UIStackView(.vertical, alignment: .center, distribution: .fill)
        if let titleElement = titleElement {
            stack.addArrangedSubview(titleElement)
        }
        if let subtitleElement = subtitleElement {
            stack.addArrangedSubview(subtitleElement)
        }
        stack.translatesAutoresizingMaskIntoConstraints = false
        itemView.addSubview(stack)
        return stack
    }

    private func setUpTitleItem(item: PMActionSheetItem?) -> UIView? {
        guard let titleItem = item else { return nil }
        let container = UIView(frame: .zero)
        var hasSetVerticalConstraint = false
        for (index, component) in titleItem.components.enumerated() {
            let previousRef = container.subviews.last?.trailingAnchor ?? container.leadingAnchor
            let element = component.makeElement()
            let isLastOne = index == titleItem.components.count - 1
            container.addSubview(element)
            let verticalOffset = component.offset?.vertical ?? 0
            element.centerYAnchor
                .constraint(equalTo: container.centerYAnchor, constant: verticalOffset)
                .isActive = true

            let leftConstraint = component.edge[3] ?? 0
            element.leadingAnchor
                .constraint(equalTo: previousRef, constant: leftConstraint)
                .isActive = true
            if isLastOne {
                let constant = component.edge[1] ?? 0
                element.trailingAnchor
                    .constraint(equalTo: container.trailingAnchor, constant: -1 * abs(constant))
                    .isActive = true
            }
            if element is UILabel, !hasSetVerticalConstraint {
                hasSetVerticalConstraint = true
                NSLayoutConstraint.activate([
                    element.topAnchor.constraint(equalTo: container.topAnchor),
                    element.bottomAnchor.constraint(equalTo: container.bottomAnchor)
                ])
            }
        }
        return container
    }

    private func setUpStackViewHorizontalConstraint(
        stackView: UIStackView,
        leftElement: UIView?,
        rightElement: UIView?
    ) {
        let hasLeft = leftElement != nil
        let hasRight = rightElement != nil

        switch (hasLeft, hasRight) {
        case (false, false):
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                stackView.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: 8)
            ])
        case (false, true):
            guard let element = rightElement else { return }
            let spacer = addSpacer(onLeftSide: true, refElement: element, component: rightItem)
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: spacer.trailingAnchor, constant: 8),
                stackView.trailingAnchor.constraint(equalTo: element.leadingAnchor, constant: -8)
            ])
        case (true, false):
            guard let element = leftElement else { return }
            let spacer = addSpacer(onLeftSide: false, refElement: element, component: leftItem)
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: element.trailingAnchor, constant: 8),
                stackView.trailingAnchor.constraint(equalTo: spacer.leadingAnchor, constant: -8)
            ])
        case (true, true):
            guard let leftElement = leftElement,
                  let rightElement = rightElement else {
                return
            }
            let rightPadding = abs((rightItem?.edge[1] ?? 16)) + rightElement.frame.size.width
            let leftPadding = (leftItem?.edge[3] ?? 16) + leftElement.frame.size.width
            if rightPadding >= leftPadding {
                let diff = rightPadding - leftPadding
                NSLayoutConstraint.activate([
                    stackView.leadingAnchor.constraint(equalTo: leftElement.trailingAnchor, constant: 8 + diff),
                    stackView.trailingAnchor.constraint(equalTo: rightElement.leadingAnchor, constant: -8)
                ])
            } else {
                let diff = leftPadding - rightPadding
                NSLayoutConstraint.activate([
                    stackView.leadingAnchor.constraint(equalTo: leftElement.trailingAnchor, constant: 8),
                    stackView.trailingAnchor.constraint(equalTo: rightElement.leadingAnchor, constant: -8 - diff)
                ])
            }
        }
    }

    private func addLine() {
        let line = UIView()
        line.backgroundColor = ColorProvider.SeparatorNorm
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.bottomAnchor.constraint(equalTo: bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1)
        ])

    }

    private func addDragBar() {
        let bar = UIView(frame: .zero)
        bar.backgroundColor = ColorProvider.InteractionWeakPressed
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.roundCorner(2)
        addSubview(bar)
        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: 40),
            bar.heightAnchor.constraint(equalToConstant: 4),
            bar.centerXAnchor.constraint(equalTo: centerXAnchor),
            bar.bottomAnchor.constraint(equalTo: itemView.topAnchor, constant: -8)
        ])
    }
}

// MARK: - Actions
extension PMActionSheetHeaderView {
    @objc
    private func clickLeftItem() {
        leftItemHandler?()
    }

    @objc
    private func clickRightItem() {
        rightItemHandler?()
    }
}

#endif
