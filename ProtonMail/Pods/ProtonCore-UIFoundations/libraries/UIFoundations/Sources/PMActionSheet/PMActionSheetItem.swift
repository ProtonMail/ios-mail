//
//  PMActionSheetItem.swift
//  ProtonCore-UIFoundations - Created on 17.07.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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

import UIKit

public protocol PMActionSheetItem {
    /// Title of item
    var title: String? { get }
    /// Icon of item
    var icon: UIImage? { get }
    /// Color of text
    var textColor: UIColor { get }
    /// Color of icon
    var iconColor: UIColor { get }
    /// A Boolean value that determines if the item is selected/ on
    var isOn: Bool { get set }
    /// Optional information about the the item.
    var userInfo: [String: Any]? { get }
}

public struct PMActionSheetItemGroup {
    public enum Style: Equatable {
        /// Items in grid style will be laid out as grid and action sheet will dismiss automatically after one of the items clicked, only support `PMActionSheetPlainItem`
        case grid
        /// Items in toggle style will be laid out as a list, only support `PMActionSheetToggleItem`
        case toggle
        /// Items in clickable style will be laid out as a list and action sheet will dismiss automatically after one of the items clicked, only support `PMActionSheetPlainItem`
        case clickable
        /// Items in singleSelection style will be laid out as a list, the checkmark will be shown when the item is selected, only support `PMActionSheetPlainItem`
        case singleSelection
        /// Items in multiSelection style will be laid out as a list, the checkmark will be shown when items are selected, only support `PMActionSheetPlainItem`
        case multiSelection
    }
    public let title: String?
    public internal(set) var items: [PMActionSheetItem]
    public let style: Style

    public init(title: String? = nil, items: [PMActionSheetItem], style: Style) {
        self.title = title
        self.items = items
        self.style = style
    }
}

public struct PMActionSheetPlainItem: PMActionSheetItem {

    public enum MarkType {
        case checkMark
        case dash
        case none

        var icon: UIImage? {
            switch self {
            case .none:
                return nil
            case .checkMark:
                return UIImage(named: "checkmark", in: PMUIFoundations.bundle, compatibleWith: nil)
            case .dash:
                return UIImage(named: "ic-minus", in: PMUIFoundations.bundle, compatibleWith: nil)
            }
        }
    }

    public let title: String?
    public let icon: UIImage?
    public let textColor: UIColor
    public let iconColor: UIColor
    /// A Boolean value that determines if the item is selected
    public var isOn: Bool = false
    public let userInfo: [String: Any]?
    /// A enum type that determines which icon shows in the right side of the cell
    public var markType: MarkType = .none {
        didSet {
            switch markType {
            case .checkMark, .dash:
                self.isOn = true
            default:
                self.isOn = false
            }
        }
    }
    /// The indentation level of the cell’s content. starts from 0
    let indentationLevel: Int
    /// The width for each level of indentation of a cell's content.
    let indentationWidth: CGFloat
    /// A block to execute when the user selects the action.
    let handler: ((PMActionSheetPlainItem) -> Void)?
    /// Alignment of title, default is `.left`
    let alignment: NSTextAlignment
    /// Does the cell have bottom separator?
    let hasSeparator: Bool

    /// Initializer of `PMActionSheetItem`
    /// - Parameters:
    ///   - title: Title of item
    ///   - icon: Icon of item
    ///   - textColor: Color of text, default value is `AdaptiveTextColors._N5`
    ///   - iconColor: Color of icon, default value is `AdaptiveTextColors._N5`
    ///   - isOn: A Boolean value that determines if the item is selected
    ///   - alignment: Alignment of title
    ///   - hasSeparator: Does the cell have bottom separator?
    ///   - userInfo: Optional information about the the item.
    ///   - indentationLevel: The indentation level of the cell’s content. starts from 0
    ///   - indentationWidth:The width for each level of indentation of a cell's content.
    ///   - handler: A block to execute when the user selects the action.
    public init(title: String?, icon: UIImage?, textColor: UIColor? = nil, iconColor: UIColor? = nil, isOn: Bool = false, markType: MarkType? = nil, alignment: NSTextAlignment = .left, hasSeparator: Bool = true, userInfo: [String: Any]? = nil, indentationLevel: Int = 0, indentationWidth: CGFloat = 24, handler: ((PMActionSheetPlainItem) -> Void)?) {
        self.title = title
        self.icon = icon
        self.textColor = textColor ?? AdaptiveTextColors._N5
        self.iconColor = iconColor ?? AdaptiveTextColors._N5
        self.markType = isOn ? .checkMark : .none
        self.isOn = isOn
        if let type = markType {
            self.markType = type
        }
        self.alignment = alignment
        self.hasSeparator = hasSeparator
        self.userInfo = userInfo
        self.indentationLevel = indentationLevel
        self.indentationWidth = indentationWidth
        self.handler = handler
    }
}

public struct PMActionSheetToggleItem: PMActionSheetItem {

    public let title: String?
    public let icon: UIImage?
    public let textColor: UIColor
    public let iconColor: UIColor
    /// A Boolean value that determines the on/off status of switch
    public var isOn: Bool
    public let userInfo: [String: Any]?
    /// Color of switch, default value is system color
    let toggleColor: UIColor?

    /// Initializer of `PMActionSheetToggleItem`
    /// - Parameters:
    ///   - title: Title of item
    ///   - icon: Icon of item
    ///   - textColor: Color of text, default value is `AdaptiveTextColors._N5`
    ///   - iconColor: Color of icon, default value is `AdaptiveTextColors._N5`
    ///   - toggleColor: Color of toggle color on `on` status, default is system value.
    ///   - isOn: A Boolean value that determines the on/off status of switch
    ///   - userInfo: Closure will excuted after item click
    public init(title: String?, icon: UIImage?, textColor: UIColor? = nil, iconColor: UIColor? = nil, toggleColor: UIColor? = nil,
                isOn: Bool = false, userInfo: [String: Any]? = nil, indentationLevel: Int = 2, indentationWidth: CGFloat = 24) {
        self.title = title
        self.icon = icon
        self.textColor = textColor ?? AdaptiveTextColors._N5
        self.iconColor = iconColor ?? AdaptiveTextColors._N5
        self.toggleColor = toggleColor
        self.isOn = isOn
        self.userInfo = userInfo
    }
}
