//
//  HumanCheckHelper.swift
//  ProtonCore-HumanVerification - Created on 2/1/16.
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

#if os(iOS)

import UIKit
import ProtonCoreAPIClient
import ProtonCoreNetworking
import ProtonCoreServices
import enum ProtonCoreDataModel.ClientApp
import ProtonCoreUIFoundations

public class HumanCheckHelper: HumanVerifyDelegate {
    private let rootViewController: UIViewController?
    private let nonModalUrls: [URL]?
    private let apiService: APIService
    private let supportURL: URL
    private var verificationCompletion: ((HumanVerifyFinishReason) -> Void)?
    var humanCheckCoordinator: HumanCheckCoordinator?
    private let clientApp: ClientApp
    private let inAppTheme: () -> InAppTheme

    // These delegates are registered and used only in login and signup
    // If set outside the LoginUI module, they will be overwritten there
    public weak var responseDelegateForLoginAndSignup: HumanVerifyResponseDelegate?
    public weak var paymentDelegateForLoginAndSignup: HumanVerifyPaymentDelegate?
    
    public init(apiService: APIService,
                supportURL: URL? = nil,
                viewController: UIViewController? = nil,
                nonModalUrls: [URL]? = nil,
                inAppTheme: @escaping () -> InAppTheme,
                clientApp: ClientApp) {
        self.apiService = apiService
        self.supportURL = supportURL ?? HVCommon.defaultSupportURL(clientApp: clientApp)
        self.rootViewController = viewController
        self.nonModalUrls = nonModalUrls
        self.inAppTheme = inAppTheme
        self.clientApp = clientApp
    }
    
    public func onHumanVerify(parameters: HumanVerifyParameters, currentURL: URL?, completion: (@escaping (HumanVerifyFinishReason) -> Void)) {
        
        // check if payment token exists
        if let paymentToken = paymentDelegateForLoginAndSignup?.paymentToken {
            let client = TestApiClient(api: self.apiService)
            let route = client.createHumanVerifyRoute(destination: nil, type: VerifyMethod(predefinedMethod: .payment), token: paymentToken)
            // retrigger request and use header with payment token
            completion(.verification(header: route.header, verificationCodeBlock: { result, _, verificationFinishBlock in
                self.paymentDelegateForLoginAndSignup?
                    .paymentTokenStatusChanged(status: result == true ? .success : .fail)
                if result {
                    verificationFinishBlock?()
                } else {
                    // if request still has an error, start human verification UI
                    self.startMenuCoordinator(parameters: parameters, currentURL: currentURL, completion: completion)
                }
            }))
        } else {
            // start human verification UI
            startMenuCoordinator(parameters: parameters, currentURL: currentURL, completion: completion)
        }
    }
    
    public func getSupportURL() -> URL {
        return supportURL
    }
    
    private func startMenuCoordinator(parameters: HumanVerifyParameters, currentURL: URL?, completion: (@escaping (HumanVerifyFinishReason) -> Void)) {
        prepareV3Coordinator(parameters: parameters, currentURL: currentURL)
        responseDelegateForLoginAndSignup?.onHumanVerifyStart()
        verificationCompletion = completion
    }
    
    private func prepareV3Coordinator(parameters: HumanVerifyParameters, currentURL: URL?) {
        var isModalPresentation = true
        if nonModalUrls?.first(where: { $0 == currentURL }) != nil {
            isModalPresentation = false
        }
        DispatchQueue.main.async {
            self.humanCheckCoordinator = HumanCheckCoordinator(rootViewController: self.rootViewController, isModalPresentation: isModalPresentation, apiService: self.apiService, parameters: parameters, inAppTheme: self.inAppTheme, clientApp: self.clientApp)
            self.humanCheckCoordinator?.delegate = self
            self.humanCheckCoordinator?.start()
        }
    }
    
    @discardableResult
    public static func removeHumanVerification(from navigationController: UINavigationController?) -> Bool {
        guard var viewControllers = navigationController?.viewControllers else { return false }
        var hvIndex: Int?
        for (index, vc) in viewControllers.enumerated() where vc is HumanVerifyViewController {
            hvIndex = index
            break
        }
        guard let index = hvIndex else { return false }
        viewControllers.remove(at: index)
        navigationController?.viewControllers = viewControllers
        return true
    }
}

extension HumanCheckHelper: HumanCheckMenuCoordinatorDelegate {
    func verificationCode(tokenType: TokenType, verificationCodeBlock: @escaping (SendVerificationCodeBlock)) {
        let client = TestApiClient(api: self.apiService)
        let route = client.createHumanVerifyRoute(destination: tokenType.destination, type: tokenType.verifyMethod, token: tokenType.token)
        responseDelegateForLoginAndSignup?
            .humanVerifyToken(token: tokenType.token, tokenType: tokenType.verifyMethod?.method)
        verificationCompletion?(.verification(header: route.header, verificationCodeBlock: { result, error, finish in
            verificationCodeBlock(result, error, finish)
            if result {
                self.responseDelegateForLoginAndSignup?.onHumanVerifyEnd(result: .success)
            }
        }))
    }
    
    func close() {
        verificationCompletion?(.close)
        self.responseDelegateForLoginAndSignup?.onHumanVerifyEnd(result: .cancel)
    }
    
    func closeWithError(code: Int, description: String) {
        verificationCompletion?(.closeWithError(code: code, description: description))
        self.responseDelegateForLoginAndSignup?.onHumanVerifyEnd(result: .cancel)
    }
}

#endif
