//
//  HumanCheckHelper.swift
//  ProtonMail - Created on 2/1/16.
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

#if canImport(UIKit)
import UIKit
import ProtonCore_APIClient
import ProtonCore_Networking
import ProtonCore_Services

public class HumanCheckHelper: HumanVerifyDelegate {
    private let rootViewController: UIViewController?
    private weak var responseDelegate: HumanVerifyResponseDelegate?
    private weak var paymentDelegate: HumanVerifyPaymentDelegate?
    private let apiService: APIService
    private let supportURL: URL
    private var verificationCompletion: ((HumanVerifyHeader, HumanVerifyIsClosed, SendVerificationCodeBlock?) -> Void)?
    var coordinator: HumanCheckMenuCoordinator?

    public init(apiService: APIService, supportURL: URL, viewController: UIViewController? = nil, responseDelegate: HumanVerifyResponseDelegate? = nil, paymentDelegate: HumanVerifyPaymentDelegate? = nil) {
        self.apiService = apiService
        self.supportURL = supportURL
        self.rootViewController = viewController
        self.responseDelegate = responseDelegate
        self.paymentDelegate = paymentDelegate
    }

    public func onHumanVerify(methods: [VerifyMethod], startToken: String?, completion: (@escaping (HumanVerifyHeader, HumanVerifyIsClosed, SendVerificationCodeBlock?) -> Void)) {

        // check if payment token exists
        if let paymentToken = paymentDelegate?.paymentToken {
            let client = TestApiClient(api: self.apiService)
            let route = client.createHumanVerifyRoute(destination: nil, type: VerifyMethod.payment, token: paymentToken)
            // retrigger request and use header with payment token
            completion(route.header, false, { result, _, verificationFinishBlock in
                self.paymentDelegate?.paymentTokenStatusChanged(status: result == true ? .success : .fail)
                if result {
                    verificationFinishBlock?()
                } else {
                    // if request still has an error, start human verification UI
                    self.startMenuCoordinator(methods: methods, startToken: startToken, completion: completion)
                }
            })
        } else {
            // start human verification UI
            startMenuCoordinator(methods: methods, startToken: startToken, completion: completion)
        }
    }

    private func startMenuCoordinator(methods: [VerifyMethod], startToken: String?, completion: (@escaping (HumanVerifyHeader, HumanVerifyIsClosed, SendVerificationCodeBlock?) -> Void)) {
        coordinator = HumanCheckMenuCoordinator(rootViewController: rootViewController, apiService: apiService, methods: methods, startToken: startToken)
        coordinator?.delegate = self
        coordinator?.start()
        responseDelegate?.onHumanVerifyStart()
        verificationCompletion = completion
    }

    public func getSupportURL() -> URL {
        return supportURL
    }
}

extension HumanCheckHelper: HumanCheckMenuCoordinatorDelegate {
    func verificationCode(tokenType: TokenType, verificationCodeBlock: @escaping (SendVerificationCodeBlock)) {
        let client = TestApiClient(api: self.apiService)
        let route = client.createHumanVerifyRoute(destination: tokenType.destination, type: tokenType.verifyMethod, token: tokenType.token)
        verificationCompletion?(route.header, false, { result, error, finish in
            verificationCodeBlock(result, error, finish)
            if result {
                self.responseDelegate?.onHumanVerifyEnd(result: .success)
            }
        })
    }

    func close() {
        verificationCompletion?([:], true, nil)
        self.responseDelegate?.onHumanVerifyEnd(result: .cancel)
    }
}

#endif
