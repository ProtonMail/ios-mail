//
//  HumanCheckHelper.swift
//  ProtonCore-HumanVerification - Created on 2/1/16.
//
//  Copyright (c) 2019 Proton Technologies AG
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

import UIKit
import ProtonCore_APIClient
import ProtonCore_Networking
import ProtonCore_Services
import enum ProtonCore_DataModel.ClientApp

public class HumanCheckHelper: HumanVerifyDelegate {
    private let rootViewController: UIViewController?
    private weak var responseDelegate: HumanVerifyResponseDelegate?
    private weak var paymentDelegate: HumanVerifyPaymentDelegate?
    private let apiService: APIService
    private let supportURL: URL
    private var verificationCompletion: ((HumanVerifyHeader, HumanVerifyIsClosed, SendVerificationCodeBlock?) -> Void)?
    var coordinator: HumanCheckMenuCoordinator?
    private var coordinatorV3: HumanCheckV3Coordinator?
    private let clientApp: ClientApp

    public init(apiService: APIService, supportURL: URL? = nil, viewController: UIViewController? = nil, clientApp: ClientApp, responseDelegate: HumanVerifyResponseDelegate? = nil, paymentDelegate: HumanVerifyPaymentDelegate? = nil) {
        self.apiService = apiService
        self.supportURL = supportURL ?? HVCommon.defaultSupportURL(clientApp: clientApp)
        self.rootViewController = viewController
        self.clientApp = clientApp
        self.responseDelegate = responseDelegate
        self.paymentDelegate = paymentDelegate
    }

    public func onHumanVerify(methods: [VerifyMethod], startToken: String?, completion: (@escaping (HumanVerifyHeader, HumanVerifyIsClosed, SendVerificationCodeBlock?) -> Void)) {
        
        // check if payment token exists
        if let paymentToken = paymentDelegate?.paymentToken {
            let client = TestApiClient(api: self.apiService)
            let route = client.createHumanVerifyRoute(destination: nil, type: VerifyMethod(predefinedMethod: .payment), token: paymentToken)
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
        if TemporaryHacks.isV3 {
            prepareV3Coordinator(methods: methods, startToken: startToken)
        } else {
            // filter only methods allowed by HV v2
            let filteredMethods = methods.compactMap { VerifyMethod(predefinedString: $0.method) }
            prepareCoordinator(methods: filteredMethods, startToken: startToken)
        }
        responseDelegate?.onHumanVerifyStart()
        verificationCompletion = completion
    }
    
    private func prepareCoordinator(methods: [VerifyMethod], startToken: String?) {
        coordinator = HumanCheckMenuCoordinator(rootViewController: rootViewController, apiService: apiService, methods: methods, startToken: startToken, clientApp: clientApp)
        coordinator?.delegate = self
        coordinator?.start()
    }
    
    private func prepareV3Coordinator(methods: [VerifyMethod], startToken: String?) {
        coordinatorV3 = HumanCheckV3Coordinator(rootViewController: rootViewController, apiService: apiService, methods: methods, startToken: startToken, clientApp: clientApp)
        coordinatorV3?.delegate = self
        coordinatorV3?.start()
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
