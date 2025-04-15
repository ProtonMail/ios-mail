// Copyright (c) 2025 Proton Technologies AG
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

import Contacts
import InboxContacts

class CNContactStorePartialStub: CNContactStoring {

    // MARK: - CNContactStoring

    class func authorizationStatus(for entityType: CNEntityType) -> CNAuthorizationStatus {
        .denied
    }

    func requestAccess(for entityType: CNEntityType, completionHandler: @escaping (Bool, (any Error)?) -> Void) {
        fatalError("Not implemented")
    }

    func enumerateContacts(
        with fetchRequest: CNContactFetchRequest,
        usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void
    ) throws {
        fatalError("Not implemented")
    }

}
