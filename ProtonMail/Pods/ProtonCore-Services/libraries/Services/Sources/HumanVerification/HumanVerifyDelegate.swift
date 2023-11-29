//
//  HumanVerifyDelegate.swift
//  ProtonCore-Services - Created on 26.04.23.
//
//  Copyright (c) 2023 Proton Technologies AG
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
import ProtonCoreNetworking

public protocol HumanVerifyDelegate: AnyObject {

    var responseDelegateForLoginAndSignup: HumanVerifyResponseDelegate? { get set }
    var paymentDelegateForLoginAndSignup: HumanVerifyPaymentDelegate? { get set }

    func onHumanVerify(parameters: HumanVerifyParameters, currentURL: URL?, completion: (@escaping (HumanVerifyFinishReason) -> Void))
    // This function calculate a device challenge using different challenge types and returns the solved hash in Base64 format.
    func onDeviceVerify(parameters: DeviceVerifyParameters) -> String?

    func getSupportURL() -> URL
}

public enum HumanVerifyFinishReason {
    public typealias HumanVerifyHeader = [String: Any]
    
    case verification(header: HumanVerifyHeader, verificationCodeBlock: SendVerificationCodeBlock?)
    case close
    case closeWithError(code: Int, description: String)
}

public protocol HumanVerifyResponseDelegate: AnyObject {
    func onHumanVerifyStart()
    func onHumanVerifyEnd(result: HumanVerifyEndResult)
    func humanVerifyToken(token: String?, tokenType: String?)
}

public enum HumanVerifyEndResult {
    case success
    case cancel
}

public protocol HumanVerifyPaymentDelegate: AnyObject {
    var paymentToken: String? { get }
    func paymentTokenStatusChanged(status: PaymentTokenStatusResult)
}

public enum PaymentTokenStatusResult {
    case success
    case fail
}

// MARK: - Deprecated

extension HumanVerifyDelegate {
    @available(*, deprecated, message: "The error parameter is no longer used, please use the version without it")
    func onHumanVerify(parameters: HumanVerifyParameters, currentURL: URL?, error _: NSError, completion: (@escaping (HumanVerifyFinishReason) -> Void)) {
        onHumanVerify(parameters: parameters, currentURL: currentURL, completion: completion)
    }
}
