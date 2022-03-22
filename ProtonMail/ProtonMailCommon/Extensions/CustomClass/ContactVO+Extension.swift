//
//  ContactVOExtension.swift
//  ProtonMail - Created on 6/21/15.
//
//
//  Copyright (c) 2019 Proton AG
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

import Foundation
import ProtonCore_DataModel

extension ContactVO {

    /// ContactVO extension for check is contactVO contained by a array of Address
    ///
    /// - Parameter addresses: addresses check addresses
    /// - Returns: true | false
    func isDuplicated(_ addresses: [Address]) -> Bool {
        return addresses.contains(where: { $0.email.lowercased() == self.email.lowercased() })
    }

    /**
     Checks if the current ContactVO is in the address list
    */
    func isDuplicatedWithContacts(_ addresses: [ContactPickerModelProtocol]) -> Bool {
        return addresses.contains(where: { ($0 as? ContactVO)?.email.lowercased() == self.email.lowercased() })
    }

    func getName(in userContacts: [ContactVO]) -> String? {
        if let userContact = userContacts.first(where: { email == $0.email }), !userContact.name.isEmpty {
            return userContact.name == userContact.email ? nil : userContact.name
        }
        return name == email ? nil : name
    }
}
