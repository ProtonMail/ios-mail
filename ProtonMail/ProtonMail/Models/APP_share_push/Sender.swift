//
//  Sender.swift
//  Proton Mail - Created on 11/12/2018.
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

/// Sender fields available for Conversation and Messages
/// They hold information that are useful when we want to parse senders as contact
/// as well as information if the sender is authenticated for whom we would show
/// a verification badge (to combat phising)
struct Sender: Codable {
    let name: String
    let address: String
    let bimiSelector: String? /// Brand Indicators for Message Identification. String to attach a logo to a sender
    private let isProton: Int?
    private let isSimpleLogin: Int?
    private let displaySenderImage: Int?

    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case address = "Address"
        case isProton = "IsProton"
        case isSimpleLogin = "IsSimpleLogin"
        case displaySenderImage = "DisplaySenderImage"
        case bimiSelector = "BimiSelector"
    }

    var isFromProton: Bool {
        isProton == 1
    }

    var isFromSimpleLogin: Bool {
        isSimpleLogin == 1
    }

    var shouldDisplaySenderImage: Bool {
        displaySenderImage == 1
    }
}

extension Sender {
    static func decodeDictionary(jsonString: String) throws -> Sender {
        try JSONDecoder().decode(Sender.self, from: Data(jsonString.utf8))
    }

    static func decodeListOfDictionaries(jsonString: String) throws -> [Sender] {
        try JSONDecoder().decode([Sender].self, from: Data(jsonString.utf8))
    }
}

enum SenderError: Error {
    case senderStringIsNil
}
