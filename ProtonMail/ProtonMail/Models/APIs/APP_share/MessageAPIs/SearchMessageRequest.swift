// Copyright (c) 2024 Proton Technologies AG
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

import ProtonCoreNetworking

struct SearchMessageRequest: Request {
    let query: SearchMessageQuery

    init(query: SearchMessageQuery) {
        self.query = query
    }

    var parameters: [String: Any]? {
        var out: [String: Any] = [:]
        out["Page"] = query.page
        if !query.labelIDs.isEmpty {
            out["LabelID"] = query.labelIDs.map { $0.rawValue }.joined(separator: ",")
        }
        if let beginTimeStamp = query.beginTimeStamp {
            out["Begin"] = beginTimeStamp
        }
        if let endTimeStamp = query.endTimeStamp {
            out["End"] = endTimeStamp
        }
        if let beginID = query.beginID {
            out["BeginID"] = beginID.rawValue
        }
        if let endID = query.endID {
            out["EndID"] = endID.rawValue
        }
        out["Keyword"] = query.keyword
        if !query.toField.isEmpty {
            out["To"] = query.toField.joined(separator: ",")
        }
        if !query.ccField.isEmpty {
            out["CC"] = query.ccField.joined(separator: ",")
        }
        if !query.bccField.isEmpty {
            out["BCC"] = query.bccField.joined(separator: ",")
        }
        if !query.fromField.isEmpty {
            out["From"] = query.fromField.joined(separator: ",")
        }
        if let subject = query.subject {
            out["Subject"] = subject
        }
        if let hasAttachments = query.hasAttachments {
            out["Attachments"] = hasAttachments.intValue
        }
        if let starred = query.starred {
            out["Starred"] = starred.intValue
        }
        if let unread = query.unread {
            out["Unread"] = unread.intValue
        }
        if let addressID = query.addressID {
            out["AddressID"] = addressID.rawValue
        }
        out["Sort"] = query.sort
        out["Desc"] = query.desc
        out["Limit"] = query.limit
        return out
    }

    var path: String { MessageAPI.path }
}

struct SearchMessageQuery {
    let page: UInt
    let labelIDs: [LabelID]
    /// UNIX timestamp to filter messages at or later than timestamp
    let beginTimeStamp: UInt?
    /// UNIX timestamp to filter messages at or earlier than timestamp
    let endTimeStamp: UInt?
    /// return only messages newer, in creation time (NOT timestamp), than BeginID
    let beginID: MessageID?
    /// return only messages older, in creation time (NOT timestamp), than EndID
    let endID: MessageID?
    /// Keyword search of To, CC, BCC, From, Subject
    let keyword: String
    let toField: [String]
    let ccField: [String]
    let bccField: [String]
    let fromField: [String]
    let subject: String?
    let hasAttachments: Bool?
    let starred: Bool?
    let unread: Bool?
    let addressID: AddressID?
    let sort: String = "Time"
    let desc: Int = 1
    let limit: UInt = 50

    init(
        page: UInt,
        labelIDs: [LabelID] = [],
        beginTimeStamp: UInt? = nil,
        endTimeStamp: UInt? = nil,
        beginID: MessageID? = nil,
        endID: MessageID? = nil,
        keyword: String,
        toField: [String] = [],
        ccField: [String] = [],
        bccField: [String] = [],
        fromField: [String] = [],
        subject: String? = nil,
        hasAttachments: Bool? = nil,
        starred: Bool? = nil,
        unread: Bool? = nil,
        addressID: AddressID? = nil
    ) {
        self.page = page
        self.labelIDs = labelIDs
        self.beginTimeStamp = beginTimeStamp
        self.endTimeStamp = endTimeStamp
        self.beginID = beginID
        self.endID = endID
        self.keyword = keyword
        self.toField = toField
        self.ccField = ccField
        self.bccField = bccField
        self.fromField = fromField
        self.subject = subject
        self.hasAttachments = hasAttachments
        self.starred = starred
        self.unread = unread
        self.addressID = addressID
    }
}
