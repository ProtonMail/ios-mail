//
//  PMActionSheetToggleItem.swift
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
import UIKit

@available(*, deprecated, message: "this will be removed. use PMActionSheetItem instead")
public class PMActionSheetToggleItem: PMActionSheetItem {

    /// Initializer of `PMActionSheetToggleItem`
    /// - Parameters:
    ///   - title: Title of item
    ///   - icon: Icon of item
    ///   - textColor: Color of text, default value is `ColorProvider.TextNorm`
    ///   - iconColor: Color of icon, default value is `ColorProvider.TextNorm`
    ///   - toggleColor: Color of toggle color on `on` status, default is system value.
    ///   - isOn: A Boolean value that determines the on/off status of switch
    ///   - userInfo: Closure will excuted after item click
    public init(
        title: String?,
        icon: UIImage?,
        textColor: UIColor? = nil,
        iconColor: UIColor? = nil,
        toggleColor: UIColor? = nil,
        isOn: Bool = false,
        userInfo: [String: Any]? = nil,
        indentationLevel: Int = 2,
        indentationWidth: CGFloat = 24
    ) {
        let config = PMActionSheetConfig.shared
        var tempComponents: [any PMActionSheetComponent] = []
        if let icon = icon {
            let iconComponent = PMActionSheetIconComponent(
                icon: icon,
                iconColor: iconColor ?? config.iconComponentColor,
                edge: [nil, nil, nil, 16]
            )
            tempComponents.append(iconComponent)
        }
        if let title = title {
            let leftPadding: CGFloat = tempComponents.isEmpty ? 16 : 13
            let textComponent = PMActionSheetTextComponent(
                text: .left(title),
                textColor: textColor ?? config.textComponentTextColor,
                edge: [nil, nil, nil, leftPadding]
            )
            tempComponents.append(textComponent)
        }

        let toggleComponent = PMActionSheetToggleComponent(
            isOn: isOn,
            onTintColor: toggleColor ?? config.toggleOnTintColor,
            edge: [nil, 16, nil, 8]
        )
        tempComponents.append(toggleComponent)

        super.init(
            components: tempComponents,
            userInfo: userInfo,
            markType: .none,
            handler: nil
        )
    }
}

#endif
