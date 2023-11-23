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

import CoreData
import Foundation

struct LabelEventProcessor {
    let userID: UserID

    func process(response: EventAPIResponse, context: NSManagedObjectContext) {
        guard let labelResponses = response.labels else {
            return
        }
        for labelResponse in labelResponses {
            guard let eventAction = EventAction(rawValue: labelResponse.action) else {
                continue
            }
            switch eventAction {
            case .delete:
                if let labelObject = Label.labelFor(labelID: labelResponse.id, userID: userID, in: context) {
                    context.delete(labelObject)
                }
            case .create, .update:
                guard let label = labelResponse.label else {
                    continue
                }
                let labelObject = Label.labelFor(labelID: label.id, userID: userID, in: context) ?? Label(context: context)
                labelObject.labelID = label.id
                labelObject.userID = userID.rawValue
                labelObject.name = label.name
                labelObject.path = label.path
                labelObject.type = NSNumber(value: label.type)
                labelObject.color = label.color
                labelObject.order = NSNumber(value: label.order)
                labelObject.notify = NSNumber(value: label.notify)
                labelObject.sticky = NSNumber(value: label.sticky)
                labelObject.parentID = label.parentId ?? .empty
            default:
                break
            }
        }
    }
}
