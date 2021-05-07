//
//  PMActionBarItem.swift
//  ProtonMail - Created on 29.07.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import UIKit

public enum PMActionBarItemType {
    ///
    case label
    case button
}

public struct PMActionBarItem {
    private(set) var icon: UIImage?
    private(set) var text: String?
    /// The technique to use for aligning the text.
    private(set) var alignment: NSTextAlignment = .left
    /// Color of bar item content, default value is `AdaptiveTextColors._N1`
    private(set) var itemColor: UIColor
    /// Color of bar item content when item is selected.
    private(set) var selectedItemColor: UIColor?
    /// Background color of bar item.
    private(set) var backgroundColor: UIColor
    /// Color when bar item is selected.
    private(set) var selectedBgColor: UIColor?
    /// A Boolean value indicating whether the control is in the selected state.
    var isSelected: Bool = false
    /// Type of bar item
    private(set) var type: PMActionBarItemType
    /// A block to execute when the user selects the action.
    private(set) var handler: ((PMActionBarItem) -> Void)?
    /// Optional information about the the bar item.
    public private(set) var userInfo: [String: Any]?

    /// Initializer of bar item(button type)
    /// - Parameters:
    ///   - icon: Icon of bar item
    ///   - itemColor: Color of bar item content, default value is `AdaptiveTextColors._N1`
    ///   - selectedItemColor: Color of bar item content when item is selected.
    ///   - backgroundColor: Background color of bar item, default value is `SolidColors._N9`
    ///   - selectedBgColor: Background color when bar item is selected.
    ///   - isSelected: A Boolean value indicating whether the control is in the selected state.
    ///   - userInfo: Optional information about the the bar item.
    ///   - handler: A block to execute when the user selects the action.
    public init(icon: UIImage,
                itemColor: UIColor = AdaptiveTextColors._N1,
                selectedItemColor: UIColor? = nil,
                backgroundColor: UIColor = SolidColors._N9,
                selectedBgColor: UIColor? = nil,
                isSelected: Bool = false,
                userInfo: [String: Any]? = nil,
                handler: ((PMActionBarItem) -> Void)?) {
        self.icon = icon
        self.itemColor = itemColor
        self.selectedItemColor = selectedItemColor
        self.backgroundColor = backgroundColor
        self.selectedBgColor = selectedBgColor
        self.handler = handler
        self.userInfo = userInfo
        self.type = .button
        self.isSelected = isSelected
    }

    /// Initializer of bar item(label type)
    /// - Parameters:
    ///   - text: Text of bar item
    ///   - alignment: The technique to use for aligning the text.
    ///   - itemColor: Color of bar item content, default value is `AdaptiveTextColors._N1`
    ///   - backgroundColor: Background color of bar item, default value is `.clear`
    public init(text: String,
                alignment: NSTextAlignment = .left,
                itemColor: UIColor = AdaptiveTextColors._N1,
                backgroundColor: UIColor = .clear) {
        self.text = text
        self.alignment = alignment
        self.itemColor = itemColor
        self.selectedItemColor = nil
        self.backgroundColor = backgroundColor
        self.selectedBgColor = nil
        self.userInfo = nil
        self.handler = nil
        self.type = .label
    }

    /// Initializer of bar item(button type)
    /// - Parameters:
    ///   - text: Text of bar item
    ///   - alignment: The technique to use for aligning the text.
    ///   - itemColor: Color of bar item content, default value is `AdaptiveTextColors._N1`
    ///   - selectedItemColor: Color of bar item content when item is selected.
    ///   - backgroundColor: Background color of bar item, default value is `.clear`
    ///   - selectedBgColor: Background color when bar item is selected.
    ///   - isSelected: A Boolean value indicating whether the control is in the selected state.
    ///   - userInfo: Optional information about the the bar item.
    ///   - handler: A block to execute when the user selects the action.
    public init(text: String,
                itemColor: UIColor = AdaptiveTextColors._N1,
                selectedItemColor: UIColor? = nil,
                backgroundColor: UIColor = .clear,
                selectedBgColor: UIColor? = nil,
                isSelected: Bool = false,
                userInfo: [String: Any]? = nil,
                handler: ((PMActionBarItem) -> Void)?) {
        self.text = text
        self.alignment = .center
        self.itemColor = itemColor
        self.selectedItemColor = selectedItemColor
        self.backgroundColor = backgroundColor
        self.selectedBgColor = selectedBgColor
        self.userInfo = userInfo
        self.handler = handler
        self.type = .button
        self.isSelected = isSelected
    }

    /// Initializer of rich bar item(button type)
    /// - Parameters:
    ///   - icon: Icon of bar item
    ///   - text: Text of bar item
    ///   - itemColor: Color of bar item content, default value is `AdaptiveTextColors._N1`
    ///   - selectedItemColor: Color of bar item content when item is selected.
    ///   - backgroundColor: Background color of bar item, default value is `.clear`
    ///   - selectedBgColor: Background color when bar item is selected.
    ///   - isSelected: A Boolean value indicating whether the control is in the selected state.
    ///   - userInfo: Optional information about the the bar item.
    ///   - handler: A block to execute when the user selects the action.
    public init(icon: UIImage,
                text: String,
                itemColor: UIColor = AdaptiveTextColors._N1,
                selectedItemColor: UIColor? = nil,
                backgroundColor: UIColor = .clear,
                selectedBgColor: UIColor? = nil,
                isSelected: Bool = false,
                userInfo: [String: Any]? = nil,
                handler: ((PMActionBarItem) -> Void)?) {
        self.icon = icon
        self.text = text
        self.alignment = .center
        self.itemColor = itemColor
        self.selectedItemColor = selectedItemColor
        self.backgroundColor = backgroundColor
        self.selectedBgColor = selectedBgColor
        self.userInfo = userInfo
        self.handler = handler
        self.type = .button
        self.isSelected = isSelected
    }
}
