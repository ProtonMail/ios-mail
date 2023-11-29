//
//  PMActionSheetComponents.swift
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

import Foundation
import enum ProtonCoreUtilities.Either
import UIKit

public protocol PMActionSheetComponent {
    associatedtype Element: UIView

    /// Constraint constants for [up, right, bottom, left]
    /// For vertical arrangement, only takes up and bottom value, right and left will be ignored
    /// For horizontal arrangement, only takes right and left value, up and bottom will be ignored
    var edge: [CGFloat?] { get }
    /// For vertical arrangement, every items is centerX, use offset.horizontal to adjust position if needed
    /// For horizontal arrangement, every items is centerY, use offset.vertical to adjust position if needed
    var offset: UIOffset? { get }

    func makeElement() -> Element
}

public struct PMActionSheetTextComponent: PMActionSheetComponent {
    public typealias Element = UILabel

    // [up, right, bottom, left]
    public let edge: [CGFloat?]
    public let offset: UIOffset?

    public let text: Either<String, NSAttributedString>
    let textColor: UIColor
    let font: UIFont
    let textAlignment: NSTextAlignment
    let compressionResistancePriority: UILayoutPriority

    public init(
        text: Either<String, NSAttributedString>,
        textColor: UIColor = PMActionSheetConfig.shared.textComponentTextColor,
        edge: [CGFloat?],
        offset: UIOffset? = nil,
        font: UIFont = PMActionSheetConfig.shared.textComponentFont,
        textAlignment: NSTextAlignment = .left,
        compressionResistancePriority: UILayoutPriority = .defaultHigh
    ) {
        assert(edge.count == 4)
        self.text = text
        self.textColor = textColor
        self.edge = edge
        self.offset = offset
        self.font = font
        self.textAlignment = textAlignment
        self.compressionResistancePriority = compressionResistancePriority
    }

    public func makeElement() -> Element {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        switch text {
        case .left(let text):
            label.text = text
        case .right(let attributedText):
            label.attributedText = attributedText
        }
        label.textColor = textColor
        label.textAlignment = textAlignment
        label.adjustsFontForContentSizeCategory = true
        label.font = font
        label.setContentCompressionResistancePriority(compressionResistancePriority, for: .horizontal)
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: 8).isActive = true
        return label
    }
}

public struct PMActionSheetButtonComponent: PMActionSheetComponent {
    public typealias Element = UIButton

    // [up, right, bottom, left]
    public let edge: [CGFloat?]
    public let offset: UIOffset?

    let content: Either<String, UIImage>
    let color: UIColor
    let font: UIFont
    let size: CGSize?
    let compressionResistancePriority: UILayoutPriority

    public init(
        content: Either<String, UIImage>,
        color: UIColor,
        size: CGSize? = nil,
        edge: [CGFloat?],
        offset: UIOffset? = nil,
        font: UIFont = PMActionSheetConfig.shared.buttonComponentFont,
        compressionResistancePriority: UILayoutPriority = .defaultHigh
    ) {
        self.edge = edge
        self.offset = offset
        self.size = size
        self.content = content
        self.color = color
        self.font = font
        self.compressionResistancePriority = compressionResistancePriority
    }

    public func makeElement() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setContentCompressionResistancePriority(compressionResistancePriority, for: .horizontal)
        switch content {
        case .left(let text):
            button.setTitle(text, for: .normal)
            button.setTitleColor(color, for: .normal)
            button.titleLabel?.font = font
        case .right(let icon):
            button.setImage(icon, for: .normal)
            button.tintColor = color
        }
        if let size = size {
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: size.width),
                button.heightAnchor.constraint(equalToConstant: size.height)
            ])
        }
        return button
    }
}

public struct PMActionSheetIconComponent: PMActionSheetComponent {
    public typealias Element = UIImageView

    public let edge: [CGFloat?]
    public let offset: UIOffset?

    let icon: UIImage
    let iconColor: UIColor
    let size: CGSize

    public init(
        icon: UIImage,
        iconColor: UIColor = PMActionSheetConfig.shared.iconComponentColor,
        size: CGSize = PMActionSheetConfig.shared.iconComponentSize,
        edge: [CGFloat?],
        offset: UIOffset? = nil
    ) {
        assert(edge.count == 4)
        self.icon = icon
        self.iconColor = iconColor
        self.size = size
        self.edge = edge
        self.offset = offset
    }

    public func makeElement() -> Element {
        let imageView = UIImageView(image: icon)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = iconColor
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: size.width),
            imageView.heightAnchor.constraint(equalToConstant: size.height)
        ])
        return imageView
    }
}

public struct PMActionSheetToggleComponent: PMActionSheetComponent {
    public typealias Element = UISwitch

    public let edge: [CGFloat?]
    public let offset: UIOffset?
    private(set) var isOn: Bool
    let onTintColor: UIColor

    public init(
        isOn: Bool,
        onTintColor: UIColor,
        edge: [CGFloat?],
        offset: UIOffset? = nil
    ) {
        self.isOn = isOn
        self.onTintColor = onTintColor
        self.edge = edge
        self.offset = offset
    }

    public func makeElement() -> UISwitch {
        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.onTintColor = onTintColor
        toggle.translatesAutoresizingMaskIntoConstraints = false
        // Size of UISwitch is fixed to (51, 31)
        // Can use transform to update size
        // toggle.transform = CGAffineTransformMakeScale(widthScale, heightScale)
        return toggle
    }

    mutating func update(isOn: Bool) {
        self.isOn = isOn
    }
}

#endif
