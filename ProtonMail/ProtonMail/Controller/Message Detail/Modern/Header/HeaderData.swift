//
//  HeaderData.swift
//  ProtonMail - Created on 08/03/2019.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

/// Incapsulates data we need for filling in the EmailHeaderView. Will not be needed once we deprecate that view.
class HeaderData: NSObject {
    let title: String
    let sender: ContactVO
    let to: [ContactVO]?
    let cc: [ContactVO]?
    let bcc: [ContactVO]?
    let isStarred: Bool
    let time: Date?
    let labels: [Label]?
    let score: Message.SpamScore
    let isSent: Bool
    
    init(message: Message) {
        self.title = message.subject
        self.sender = message.senderContactVO
        self.to = message.toList.toContacts()
        self.cc = message.ccList.toContacts()
        self.bcc = message.bccList.toContacts()
        self.isStarred = message.starred
        self.time = message.time
        self.labels = message.labels.allObjects as? [Label]
        self.score = message.getScore()
        self.isSent = message.contains(label: .sent)
    }
}

extension EmailHeaderView {
    func updateHeaderData(_ headerData: HeaderData) {
        self.updateHeaderData(headerData.title,
                              sender: headerData.sender,
                              to: headerData.to,
                              cc: headerData.cc,
                              bcc: headerData.bcc,
                              isStarred: headerData.isStarred,
                              time: headerData.time,
                              labels: headerData.labels,
                              showShowImages: false,
                              expiration: nil,
                              score: headerData.score,
                              isSent: headerData.isSent)
    }
}
