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
        return senderName.shortName()
    }

    func getLabelIds() -> [String] {
        self.labels.compactMap({ $0 as? ContextLabel }).map({ $0.labelID })
    }

    func firstValidFolder() -> String? {
        for labelId in getLabelIds() {
            if !labelId.preg_match ("(?!^\\d+$)^.+$") {
                if labelId != "1", labelId != "2", labelId != "10", labelId != "5" {
                    return labelId
                }
            }
        }
        
        return nil
    }

    func getFolderIcons(customFolderLabels: [Label]) -> [UIImage] {
        let labelIds = getLabelIds()
        let standardFolders: [String] = [
            Message.Location.inbox,
            Message.Location.trash,
            Message.Location.spam,
            Message.Location.archive,
            Message.Location.sent,
            Message.Location.draft
        ].map({ $0.rawValue })

        // Display order: Inbox, Custom, Drafts, Sent, Archive, Spam, Trash
        let standardFolderWithOrder: [Message.Location: Int] = [
            .inbox: 0,
            .draft: 2,
            .sent: 3,
            .archive: 4,
            .spam: 5,
            .trash: 6
        ]

        let customLabelIdsMap = customFolderLabels.reduce([:]) { result, label -> [String : Label] in
            var newValue = result
            newValue[label.labelID] = label
            return newValue
        }

        var addedDict: [UIImage: Bool] = [:]
        let filteredLabelIds = labelIds.filter { labelId in
            return (customLabelIdsMap[labelId] != nil) || standardFolders.contains(labelId)
        }

        let sortedLabelIds = filteredLabelIds.sorted { labelId1, labelId2 in
            var orderOfLabelId1 = Int.max
            if let location = Message.Location.init(rawValue: labelId1) {
                orderOfLabelId1 = standardFolderWithOrder[location] ?? Int.max
            } else {
                orderOfLabelId1 = 1
            }

            var orderOfLabelId2 = Int.max
            if let location = Message.Location.init(rawValue: labelId2) {
                orderOfLabelId2 = standardFolderWithOrder[location] ?? Int.max
            } else {
                orderOfLabelId2 = 1
            }

            return orderOfLabelId1 < orderOfLabelId2
        }

        var isCustomFolderIconAdded = false
        return Array(sortedLabelIds.compactMap { lableId in
            var icon: UIImage?
            if standardFolders.contains(lableId) {
                if let location = Message.Location.init(rawValue: lableId) {
                    icon = location.originImage()
                }
            } else if !isCustomFolderIconAdded {
                isCustomFolderIconAdded = true
                icon = Asset.mailCustomFolder.image
            }
            if let iconToAdd = icon,
               addedDict.updateValue(true, forKey: iconToAdd) == nil { // filter duplicated icon
                return iconToAdd
            } else {
                return nil
            }
        }.prefix(3))
    }

    func getOrderedLabels() -> [Label] {
        let labels = self.getLabels()
        let predicate = NSPredicate(format: "labelID MATCHES %@", "(?!^\\d+$)^.+$")
        let allLabels = NSArray(array: labels).filtered(using: predicate)
        return allLabels
            .compactMap({ $0 as? Label })
            .sorted(by: { $0.order.intValue < $1.order.intValue })
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
        return TagViewModel(
            title: expirationTime.countExpirationTime.apply(style: FontManager.OverlineRegularInteractionStrong),
            icon: Asset.mailHourglass.image,
            color: UIColorManager.InteractionWeak
        )
    }

    func createTags() -> [TagViewModel] {
        return [createTagFromExpirationDate()].compactMap { $0 } + tagViewModels
    }
}
