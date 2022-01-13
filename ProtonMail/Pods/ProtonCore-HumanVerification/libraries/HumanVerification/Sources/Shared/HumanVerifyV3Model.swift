//
//  HumanVerifyV3Model.swift
//  ProtonCore-HumanVerification - Created on 20/01/21.
//
//  Copyright (c) 2021 Proton Technologies AG
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
import ProtonCore_Networking

struct TokenType {
    var destination: String?
    let verifyMethod: VerifyMethod?
    let token: String?
}

protocol HumanCheckMenuCoordinatorDelegate: AnyObject {
    func verificationCode(tokenType: TokenType,
                          verificationCodeBlock: (@escaping SendVerificationCodeBlock))
    func close()
    func closeWithError(code: Int, description: String)
}

enum NotificationType: String, Codable {
    case error
    case warning
    case info
    case success
}

enum MessageType: String, Codable {
    case human_verification_success = "HUMAN_VERIFICATION_SUCCESS"
    case notification = "NOTIFICATION"
    case resize = "RESIZE"
    case close = "CLOSE"
    case loaded = "LOADED"
}

struct MessageSuccess: Codable {
    let type: MessageType
    let payload: PayloadSuccess
}

struct PayloadSuccess: Codable {
    let token: String
    let type: String
}

struct MessageNotification: Codable {
    let type: MessageType
    let payload: PayloadNotification
}

struct PayloadNotification: Codable {
    let type: NotificationType
    let text: String
}

struct MessageResize: Codable {
    let type: MessageType
    let payload: PayloadResize
}

struct PayloadResize: Codable {
    let height: Float
}
