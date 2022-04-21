//
//  Conversation+Var+Extension.swift
//  ProtonMail
//
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

import UIKit
import ProtonCore_UIFoundations

extension Conversation {
    var starred: Bool {
        return contains(of: Message.Location.starred.rawValue)
    }

    var draft: Bool {
        return contains(of: Message.Location.draft.rawValue)
    }

    func initial(_ replacingEmails: [Email]) -> String {
        guard let senderName = getSendersName(replacingEmails).first else {
            return "?"
        }
        return senderName.initials()
    }

    func getLabelIds() -> [String] {
        self.labels.compactMap({ $0 as? ContextLabel }).map({ $0.labelID })
    }

    func firstValidFolder() -> String? {
        for labelId in getLabelIds() {
            if !labelId.preg_match("(?!^\\d+$)^.+$") {
                if labelId != "1", labelId != "2", labelId != "10", labelId != "5" {
                    return labelId
                }
            }
        }

        return nil
    }

    func getOrderedLabels() -> [LabelEntity] {
        let labels = self.getLabels()
        let predicate = NSPredicate(format: "labelID MATCHES %@", "(?!^\\d+$)^.+$")
        let allLabels = NSArray(array: labels).filtered(using: predicate)
        return allLabels
            .compactMap({ $0 as? Label })
            .sorted(by: { $0.order.intValue < $1.order.intValue })
            .compactMap(LabelEntity.init)
    }

    var tagViewModels: [TagViewModel] {
        getOrderedLabels().map { label in
            TagViewModel(title: label.name.apply(style: FontManager.OverlineSemiBoldTextInverted),
                         icon: nil,
                         color: UIColor(hexString: label.color, alpha: 1.0))
        }
    }

    func createTagFromExpirationDate() -> TagViewModel? {
        guard let expirationTime = expirationTime else { return nil }
        let title = expirationTime
            .countExpirationTime(processInfo: userCachedStatus)
            .apply(style: FontManager.OverlineRegularInteractionStrong)
        return TagViewModel(
            title: title,
            icon: Asset.mailHourglass.image,
            color: ColorProvider.InteractionWeak
        )
    }

    func createTags() -> [TagViewModel] {
        return [createTagFromExpirationDate()].compactMap { $0 } + tagViewModels
    }
}
