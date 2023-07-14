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
import UIKit

@available(*, deprecated, message: "this will be removed. use PMActionSheetItem instead")
public class PMActionSheetPlainItem: PMActionSheetItem {
    public let title: String?
    let icon: UIImage?

    public init(
        title: String?,
        icon: UIImage?,
        textColor: UIColor? = nil,
        iconColor: UIColor? = nil,
        isOn: Bool = false,
        markType: MarkType? = nil,
        alignment: NSTextAlignment = .left,
        hasSeparator: Bool = true,
        userInfo: [String: Any]? = nil,
        indentationLevel: Int = 0,
        indentationWidth: CGFloat = 24,
        handler: ((PMActionSheetItem) -> Void)?
    ) {
        self.title = title
        self.icon = icon

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
                edge: [nil, nil, nil, leftPadding],
                textAlignment: alignment
            )
            tempComponents.append(textComponent)
        }

        var _markType: PMActionSheetItem.MarkType
        if isOn == false {
            _markType = .none
        } else {
            _markType = .checkMark
            if let type = markType {
                _markType = type
            }
        }

        super.init(
            components: tempComponents,
            indentationLevel: indentationLevel,
            indentationWidth: indentationWidth,
            hasSeparator: hasSeparator,
            userInfo: userInfo,
            markType: _markType,
            handler: handler
        )
    }
}

#endif
