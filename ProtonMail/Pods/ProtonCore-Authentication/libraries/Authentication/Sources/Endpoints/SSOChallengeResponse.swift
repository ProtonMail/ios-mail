//
//  SSOChallengeResponse.swift
//  ProtonCore-Authentication - Created on 20/02/2020.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreServices
import ProtonCoreNetworking
import ProtonCoreUtilities

public final class SSOChallengeResponse: Response, APIDecodableResponse {
    public var ssoChallengeToken: String

    public init(ssoChallengeToken: String) {
        self.ssoChallengeToken = ssoChallengeToken
    }

    public convenience init(_ response: [String: Any]) throws {
        guard let ssoChallengeToken = response["SSOChallengeToken"] as? String else {
            throw AuthErrors.switchToSRPError
        }
        self.init(ssoChallengeToken: ssoChallengeToken)
    }

    @available(*, unavailable)
    required init() {
        fatalError("init() has not been implemented")
    }

    enum CodingKeys: String, CodingKey {
        case ssoChallengeToken = "SSOChallengeToken"
    }
}
