//
//  ConversationsAPI.swift
//  ProtonMail
//
//
//  Copyright (c) 2020 Proton AG
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
import ProtonCore_Networking

// Get a list of conversations
class ConversationsRequest: Request {
    struct Parameters {
        var location: Int?
        var page: Int?
        var pageSize: Int?
        var limit: Int?
        var labelID: String?
        var desc: Int?
        var begin: Int?
        var end: Int?
        var beginID: String?
        var endID: String?
        var keyword: String?
        var to: String?
        var from: String?
        var subject: String?
        var attachments: Int?
        var starred: Int?
        var unread: Int?
        var addressID: String?
        var sort: String?
        var IDs: [String]?

        struct Pair: Equatable {
            var key, value: String
        }

        var additionalPathElements: [Pair]? {
            var path = [Pair]()
            let mirror = Mirror(reflecting: self)

            for case let (label?, anyValue) in mirror.children {
                switch anyValue {
                case Optional<Any>.none:
                    break
                case Optional<Any>.some(let value) where value is [String]:
                    if let array = value as? [String] {
                        array.forEach {
                            path.append(.init(key: label + "[]", value: "\($0)"))
                        }
                    }
                case Optional<Any>.some(let value):
                    path.append(.init(key: label, value: "\(value)"))
                default:
                    assert(false, "Reflection broken")
                }
            }
            // return dict only if there is at least one non-empty value
            return path.first(where: { !$0.value.isEmpty }) == nil ? nil : path
        }
    }

    private var parameters: Parameters

    init(_ parameters: Parameters = Parameters()) {
        self.parameters = parameters
    }

    private func buildURL() -> String {
        var out = ""
        if let params = parameters.additionalPathElements {
            out.append("?")
            out.append(params.map { $0.key.first!.uppercased() + $0.key.dropFirst() + "=" + $0.value }.joined(separator: "&"))
        }
        return out
    }

    var path: String {
        return ConversationsAPI.path + buildURL()
    }
}

class ConversationsResponse: Response {
    var total: Int?
    var conversationsDict: [[String: Any]] = []
    var responseDict: [String: Any]?
    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        responseDict = response
        total = response["Total"] as? Int

        guard let conversationJson = response["Conversations"] as? [[String: Any]] else {
            return false
        }

        conversationsDict = conversationJson
        return true
    }
}
