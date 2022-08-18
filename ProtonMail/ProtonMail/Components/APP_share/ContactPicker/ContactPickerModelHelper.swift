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

struct ContactPickerModelHelper {
    static func contacts(from jsonContact: String) -> [ContactPickerModelProtocol] {
        guard let recipients = jsonContact.parseJson() else { return [] }
        var results: [ContactPickerModelProtocol] = []
        // [groupName: [DraftEmailData]]
        var groups: [String: [DraftEmailData]] = [:]
        for dict in recipients {
            let group = dict["Group"] as? String ?? ""
            let name = dict["Name"] as? String ?? ""
            let address = dict["Address"] as? String ?? ""

            if group.isEmpty {
                // contact
                results.append(ContactVO(id: "", name: name, email: address))
            } else {
                // contact group
                let toInsert = DraftEmailData(name: name, email: address)
                if var data = groups[group] {
                    data.append(toInsert)
                    groups.updateValue(data, forKey: group)
                } else {
                    groups.updateValue([toInsert], forKey: group)
                }
            }
        }

        for group in groups {
            let contactGroup = ContactGroupVO(ID: "", name: group.key)
            contactGroup.overwriteSelectedEmails(with: group.value)
            results.append(contactGroup)
        }
        return results
    }
}
