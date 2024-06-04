// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCoreUIFoundations
import UIKit

extension PMActionSheetItem {
    convenience init(
        title: String?,
        icon: UIImage?,
        textColor: UIColor? = nil,
        iconColor: UIColor? = nil,
        isOn: Bool = false,
        markType: PMActionSheetItem.MarkType? = nil,
        alignment: NSTextAlignment = .left,
        hasSeparator: Bool = true,
        userInfo: [String: Any]? = nil,
        indentationLevel: Int = 0,
        indentationWidth: CGFloat = 24,
        handler: ((PMActionSheetItem) -> Void)?
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
                edge: [nil, nil, nil, leftPadding],
                textAlignment: alignment
            )
            tempComponents.append(textComponent)
        }

        var type: PMActionSheetItem.MarkType
        if isOn == false {
            type = .none
        } else {
            type = .checkMark
            if let selectedType = markType {
                type = selectedType
            }
        }
        self.init(
            components: tempComponents,
            indentationLevel: indentationLevel,
            indentationWidth: indentationWidth,
            hasSeparator: hasSeparator,
            userInfo: userInfo,
            markType: type,
            handler: handler
        )
    }
}
