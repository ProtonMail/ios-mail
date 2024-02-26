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
    let sort: String
    let desc: Int
    let limit: UInt

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
        addressID: AddressID? = nil,
        sort: String = "Time",
        desc: Bool = true,
        limit: UInt = 50
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
        self.sort = sort
        self.desc = desc.intValue
        self.limit = limit
    }

    var parameters: [String: Any]? {
        var out: [String: Any] = [:]
        out["Page"] = page
        if !labelIDs.isEmpty {
            out["LabelID"] = labelIDs.map { $0.rawValue }.joined(separator: ",")
        }
        if let beginTimeStamp {
            out["Begin"] = beginTimeStamp
        }
        if let endTimeStamp {
            out["End"] = endTimeStamp
        }
        if let beginID {
            out["BeginID"] = beginID.rawValue
        }
        if let endID {
            out["EndID"] = endID.rawValue
        }
        out["Keyword"] = keyword
        if !toField.isEmpty {
            out["To"] = toField.joined(separator: ",")
        }
        if !ccField.isEmpty {
            out["CC"] = ccField.joined(separator: ",")
        }
        if !bccField.isEmpty {
            out["BCC"] = bccField.joined(separator: ",")
        }
        if !fromField.isEmpty {
            out["From"] = fromField.joined(separator: ",")
        }
        if let subject {
            out["Subject"] = subject
        }
        if let hasAttachments {
            out["Attachments"] = hasAttachments.intValue
        }
        if let starred {
            out["Starred"] = starred.intValue
        }
        if let unread {
            out["Unread"] = unread.intValue
        }
        if let addressID {
            out["AddressID"] = addressID.rawValue
        }
        out["Sort"] = sort
        out["Desc"] = desc
        out["Limit"] = limit
        return out
    }

    var path: String { MessageAPI.path }
}
