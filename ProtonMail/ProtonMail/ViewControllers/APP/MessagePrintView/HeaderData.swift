//
//  HeaderData.swift
//  Proton Mail - Created on 08/03/2019.
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

/// Incapsulates data we need for filling in the PrintHeaderView. Will not be needed once we deprecate that view.
class HeaderData: NSObject {
    let title: String
    let sender: ContactVO
    let to: [ContactVO]?
    let cc: [ContactVO]?
    let bcc: [ContactVO]?
    let time: Date?
    let labels: [LabelEntity]?
    
    init(message: MessageEntity) {
        self.title = message.title
        do {
            let sender = try message.parseSender()
            self.sender = ContactVO(name: sender.name, email: sender.address)
        } catch {
            assertionFailure("\(error)")
            self.sender = ContactVO(name: "Unknown", email: "Unknown")
        }
        self.to = ContactPickerModelHelper.nonGroupContacts(from: message.rawTOList)
        self.cc = ContactPickerModelHelper.nonGroupContacts(from: message.rawCCList)
        self.bcc = ContactPickerModelHelper.nonGroupContacts(from: message.rawBCCList)
        self.time = message.time
        self.labels = message.labels
    }
}
