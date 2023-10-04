//
//  PMActionSheetPlainItem.swift
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

import Foundation
import enum ProtonCoreUtilities.Either
import UIKit

public class PMActionSheetItem {
    public private(set) var components: [any PMActionSheetComponent]
    /// A block to execute when the user selects the action.
    let handler: ((PMActionSheetItem) -> Void)?
    public let userInfo: [String: Any]?
    /// The indentation level of the cell’s content. starts from 0
    let indentationLevel: Int
    /// The width for each level of indentation of a cell's content.
    let indentationWidth: CGFloat
    let hasSeparator: Bool
    public internal(set) var markType: MarkType = .none
    public internal(set) var toggleState: Bool {
        get {
            guard let index = components.firstIndex(where: { $0 is PMActionSheetToggleComponent }),
                  let toggle = components[safeIndex: index] as? PMActionSheetToggleComponent else {
                return false
            }
            return toggle.isOn
        }
        set {
            guard let index = components.firstIndex(where: { $0 is PMActionSheetToggleComponent }),
                  var toggle = components[safeIndex: index] as? PMActionSheetToggleComponent else {
                return
            }
            toggle.update(isOn: newValue)
            components[index] = toggle
        }
    }

    public init(
        components: [any PMActionSheetComponent],
        indentationLevel: Int = 0,
        indentationWidth: CGFloat = PMActionSheetConfig.shared.indentationWidth,
        hasSeparator: Bool = true,
        userInfo: [String: Any]? = nil,
        markType: MarkType = .none,
        handler: ((PMActionSheetItem) -> Void)?
    ) {
        self.components = components
        self.indentationLevel = indentationLevel
        self.indentationWidth = indentationWidth
        self.hasSeparator = hasSeparator
        self.userInfo = userInfo
        self.markType = markType
        self.handler = handler
    }

    public convenience init(
        style: Style,
        indentationLevel: Int = 0,
        indentationWidth: CGFloat = PMActionSheetConfig.shared.indentationWidth,
        hasSeparator: Bool = true,
        userInfo: [String: Any]? = nil,
        markType: MarkType = .none,
        handler: ((PMActionSheetItem) -> Void)?
    ) {
        self.init(
            components: PMActionSheetItem.makeComponent(style: style),
            indentationLevel: indentationLevel,
            indentationWidth: indentationWidth,
            hasSeparator: hasSeparator,
            userInfo: userInfo,
            markType: markType,
            handler: handler
        )
    }

    private static func makeComponent(style: Style) -> [any PMActionSheetComponent] {
        switch style {
        case .`default`(let icon, let text):
            let icComponent = PMActionSheetIconComponent(icon: icon, edge: [nil, nil, nil, 16])
            let textComponent = PMActionSheetTextComponent(text: .left(text), edge: [nil, 16, nil, 12])
            return [icComponent, textComponent]
        case .twoColumn(let leftText, let rightText):
            let leftComponent = PMActionSheetTextComponent(text: .left(leftText), edge: [nil, nil, nil, 16])
            let rightComponent = PMActionSheetTextComponent(
                text: .left(rightText),
                textColor: PMActionSheetConfig.shared.twoColumnRightTextColor,
                edge: [nil, 16, nil, 8],
                textAlignment: .right,
                compressionResistancePriority: .required
            )
            return [leftComponent, rightComponent]
        case .toggle(let text, let isOn):
            let textComponent = PMActionSheetTextComponent(text: .left(text), edge: [nil, nil, nil, 16])
            let toggleComponent = PMActionSheetToggleComponent(
                isOn: isOn,
                onTintColor: PMActionSheetConfig.shared.toggleOnTintColor,
                edge: [nil, 16, nil, 8]
            )
            return [textComponent, toggleComponent]
        case .text(let text):
            let textComponent = PMActionSheetTextComponent(text: .left(text), edge: [nil, nil, nil, 16])
            return [textComponent]
        case .grid(let icon, let text):
            let icComponent = PMActionSheetIconComponent(
                icon: icon,
                iconColor: PMActionSheetConfig.shared.gridIconColor,
                edge: [14, nil, nil, nil]
            )
            let textComponent = PMActionSheetTextComponent(
                text: .left(text),
                textColor: PMActionSheetConfig.shared.gridTextColor,
                edge: [4, nil, 11, nil],
                font: PMActionSheetConfig.shared.gridTextFont
            )
            return [icComponent, textComponent]
        }
    }

    public func update(markType: MarkType) {
        self.markType = markType
    }
}

extension PMActionSheetItem {
    public enum Style {
        // |-16-icon-12-text-16-|
        case `default`(UIImage, String)
        // |-16-text-8-text-16-|
        case twoColumn(String, String)
        // |-16-text-8-toggle-16-|
        // (text, isOn)
        case toggle(String, Bool)
        // |-16-text-|
        case text(String)
        // from top to bottom
        // |-14-icon-4-text-11-|
        case grid(UIImage, String)
    }

    public enum MarkType {
        case checkMark
        case dash
        case none

        var icon: UIImage? {
            switch self {
            case .none:
                return nil
            case .checkMark:
                return IconProvider.checkmark
            case .dash:
                return IconProvider.minus
            }
        }

        var iconNewStyle: UIImage? {
            switch self {
            case .none:
                return IconProvider.circle
            case .checkMark:
                return IconProvider.checkmarkCircleFilled
            case .dash:
                return IconProvider.minusCircle
            }
        }

        var isSelected: Bool {
            switch self {
            case .none:
                return false
            case .checkMark, .dash:
                return true
            }
        }
    }
}

#endif
