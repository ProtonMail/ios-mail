// Copyright (c) 2022 Proton AG
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

import Foundation
import ProtonCore_UIFoundations
import UIKit

// MARK: Extended variable only for host app
extension MessageEntity {
    var tagUIModels: [TagUIModel] {
        orderedLabel.map { label in
            TagUIModel(
                title: label.name,
                titleColor: .white,
                titleWeight: .semibold,
                icon: nil,
                tagColor: UIColor(hexString: label.color, alpha: 1.0)
            )
        }
    }

    var spam: SpamType? {
        if flag.contains(.dmarcFailed) {
            return .dmarcFailed
        }
        let isSpam = self.labels
            .map(\.labelID.rawValue)
            .contains(Message.Location.spam.rawValue)
        return flag.contains(.autoPhishing) && (!flag.contains(.hamManual) || isSpam) ? .autoPhishing : nil
    }
}

// MARK: Helper functions only for host app
extension MessageEntity {
    func getLocationImage(in labelID: LabelID,
                          viewMode: ViewMode = .singleMessage) -> UIImage? {
        let location = self.labels
            .filter { $0.labelID == labelID }
            .compactMap { LabelLocation.init(labelID: $0.labelID, name: $0.name) }
            .first(where: { $0 != .allmail && $0 != .starred })

        guard location == .draft else {
            return location?.icon
        }
        if viewMode == .singleMessage {
           return Asset.mailDraftIcon.image
        } else {
            return Asset.mailConversationDraft.image
        }
    }

    func getFolderMessageLocation(customFolderLabels: [LabelEntity]) -> LabelLocation? {
        let labelIds = getLabelIDs()
        let standardFolders: [LabelID] = [
            Message.Location.inbox,
            Message.Location.trash,
            Message.Location.spam,
            Message.Location.archive,
            Message.Location.sent,
            Message.Location.draft
        ].map({ $0.labelID })

        let customLabelIdsMap = customFolderLabels.reduce([:]) { result, label -> [LabelID: LabelEntity] in
            var newValue = result
            newValue[label.labelID] = label
            return newValue
        }

        let labels: [LabelLocation] = labelIds
            .filter { labelID in
                (customLabelIdsMap[labelID] != nil) || standardFolders.contains(labelID)
            }
            .compactMap { labelID in
                if standardFolders.contains(labelID) {
                    if Message.Location(labelID) != nil {
                        return LabelLocation(id: labelID.rawValue, name: nil)
                    } else {
                        return nil
                    }
                } else {
                    return LabelLocation(id: labelID.rawValue, name: nil)
                }
            }

        return labels.first
    }

    func getFolderIcons(customFolderLabels: [LabelEntity]) -> [UIImage] {
        let labelIds = getLabelIDs()
        let standardFolders: [LabelID] = [
            Message.Location.inbox,
            Message.Location.trash,
            Message.Location.spam,
            Message.Location.archive,
            Message.Location.sent,
            Message.Location.draft
        ].map({ $0.labelID })

        let customLabelIdsMap = customFolderLabels.reduce([:]) { result, label -> [LabelID: LabelEntity] in
            var newValue = result
            newValue[label.labelID] = label
            return newValue
        }

        return labelIds.filter { labelId in
            return (customLabelIdsMap[labelId] != nil) || standardFolders.contains(labelId)
        }.compactMap { lableId in
            if standardFolders.contains(lableId) {
                if let location = Message.Location(lableId) {
                    return location.originImage()
                } else {
                    return nil
                }
            }
            // TODO: return colored icon accroding to folder
            return Asset.mailCustomFolder.image
        }
    }

    func createTagFromExpirationDate() -> TagUIModel? {
        guard let expirationTime = expirationTime,
              messageLocation != .draft else { return nil }
        let title = expirationTime
            .countExpirationTime(processInfo: userCachedStatus)
        return TagUIModel(
            title: title,
            titleColor: ColorProvider.InteractionStrong,
            titleWeight: .regular,
            icon: IconProvider.hourglass,
            tagColor: ColorProvider.InteractionWeak
        )
    }

    func createTags() -> [TagUIModel] {
        [createTagFromExpirationDate()].compactMap { $0 } + tagUIModels
    }
}
