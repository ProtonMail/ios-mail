// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

struct LabelEntity: Hashable {
    enum LabelType: Int {
        case messageLabel = 1
        case contactGroup = 2
        case folder = 3
    }

    // MARK: Properties
    private(set) var userID: UserID
    private(set) var labelID: LabelID
    private(set) var parentID: LabelID
    let objectID: ObjectID
    private(set) var name: String
    private(set) var color: String
    private(set) var type: LabelType
    /// 0 => not sticky, 1 => stick to the page in the sidebar
    private(set) var sticky: Bool
    /// start at 1 , lower number on the top
    private(set) var order: Int = 1
    private(set) var path: String
    private(set) var notify: Bool

    // MARK: Relations
    private(set) var emailRelations: [EmailEntity]?

    // MARK: Local properties
    private(set) var isSoftDeleted: Bool

    init(label: Label) {
        self.userID = UserID(label.userID)
        self.labelID = LabelID(label.labelID)
        self.parentID = LabelID(label.parentID)
        self.objectID = ObjectID(rawValue: label.objectID)
        self.name = label.name
        self.color = label.color
        self.type = LabelType(rawValue: label.type.intValue) ?? .messageLabel
        self.sticky = label.sticky.boolValue
        self.order = label.order.intValue
        self.path = label.path
        self.notify = label.notify.boolValue

        self.emailRelations = EmailEntity.convert(from: label.emails)

        self.isSoftDeleted = label.isSoftDeleted
    }

    static func convert(from labels: NSSet) -> [LabelEntity] {
        labels.allObjects.compactMap { item in
            guard let data = item as? Label else { return nil }
            return LabelEntity(label: data)
        }
    }
}
