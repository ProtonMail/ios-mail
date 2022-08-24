//
//  Conversation+Var+Extension.swift
//  Proton Mail
//
//
//  Copyright (c) 2020 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_UIFoundations

extension Conversation {

    func getOrderedLabels() -> [LabelEntity] {
        let labels = self.getLabels()
        let predicate = NSPredicate(format: "labelID MATCHES %@", "(?!^\\d+$)^.+$")
        let allLabels = NSArray(array: labels).filtered(using: predicate)
        return allLabels
            .compactMap({ $0 as? Label })
            .sorted(by: { $0.order.intValue < $1.order.intValue })
            .compactMap(LabelEntity.init)
    }

    var tagUIModels: [TagUIModel] {
        getOrderedLabels().map { label in
            TagUIModel(title: label.name.apply(style: FontManager.OverlineSemiBoldTextInverted),
                         icon: nil,
                         color: UIColor(hexString: label.color, alpha: 1.0))
        }
    }

    func createTagFromExpirationDate() -> TagUIModel? {
        guard let expirationTime = expirationTime else { return nil }
        let title = expirationTime
            .countExpirationTime(processInfo: userCachedStatus)
            .apply(style: FontManager.OverlineRegularInteractionStrong)
        return TagUIModel(
            title: title,
            icon: IconProvider.hourglass,
            color: ColorProvider.InteractionWeak
        )
    }

    func createTags() -> [TagUIModel] {
        return [createTagFromExpirationDate()].compactMap { $0 } + tagUIModels
    }
}
