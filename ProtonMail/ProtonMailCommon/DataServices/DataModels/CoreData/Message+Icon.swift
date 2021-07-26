//
//  Message+Icon.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

import Foundation

extension Message {
    func getFolderIcons(customFolderLabels: [Label]) -> [UIImage] {
        let labelIds = getLabelIDs()
        let standardFolders: [String] = [
            Message.Location.inbox,
            Message.Location.trash,
            Message.Location.spam,
            Message.Location.archive,
            Message.Location.sent,
            Message.Location.draft
        ].map({ $0.rawValue })

        let customLabelIdsMap = customFolderLabels.reduce([:]) { result, label -> [String : Label] in
            var newValue = result
            newValue[label.labelID] = label
            return newValue
        }

        return labelIds.filter { labelId in
            return (customLabelIdsMap[labelId] != nil) || standardFolders.contains(labelId)
        }.compactMap { lableId in
            if standardFolders.contains(lableId) {
                if let location = Message.Location.init(rawValue: lableId) {
                    return location.originImage()
                } else {
                    return nil
                }
            }
            // TODO: return colored icon accroding to folder
            return Asset.mailCustomFolder.image
        }
    }
}
