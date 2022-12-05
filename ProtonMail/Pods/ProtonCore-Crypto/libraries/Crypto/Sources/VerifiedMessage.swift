//
//  VerifiedMessage.swift
//  ProtonCore-Crypto - Created on 07/19/22.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation

// verified message template. use when decrypting the message and pass in the verifier.
// if verify pass. it will return the content without clear value.
// if verify failed. it will return the content plus the error
public enum VerifiedMessage<ClearContent> {
    case verified(ClearContent)
    case unverified(ClearContent, Error)
}

public typealias VerifiedString = VerifiedMessage<String>
public typealias VerifiedData = VerifiedMessage<Data>

extension VerifiedMessage {
    public var content: ClearContent {
        switch self {
        case .verified(let content):
            return content
        case .unverified(let content, _):
            return content
        }
    }

    func map<NewContent>(_ transform: (ClearContent) throws -> NewContent) rethrows -> VerifiedMessage<NewContent> {
        let mappedContent = try transform(content)

        switch self {
        case .verified:
            return .verified(mappedContent)
        case let .unverified(_, error):
            return .unverified(mappedContent, error)
        }
    }
}
