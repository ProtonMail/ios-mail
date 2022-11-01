//
//  RecaptchaViewModel.swift
//  ProtonCore-HumanVerification - Created on 20/01/21.
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

import WebKit
import enum ProtonCore_DataModel.ClientApp
import ProtonCore_Log
import ProtonCore_Doh
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_UIFoundations
import ProtonCore_CoreTranslation

final class WeaklyProxingScriptHandler<OtherHandler: WKScriptMessageHandler>: NSObject, WKScriptMessageHandler {
    private weak var otherHandler: OtherHandler?
    
    init(_ otherHandler: OtherHandler) { self.otherHandler = otherHandler }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let otherHandler = otherHandler else { return }
        otherHandler.userContentController(userContentController, didReceive: message)
    }
}

class HumanVerifyV3ViewModel {

    // MARK: - Private properties

    private var token: String?
    private var tokenMethod: VerifyMethod?

    let apiService: APIService
    let clientApp: ClientApp
    let scriptName = "iOS"
    
    var startToken: String?
    var methods: [VerifyMethod]?
    var onVerificationCodeBlock: ((@escaping SendVerificationCodeBlock) -> Void)?
    
    // the order matters, methods below assume it's kept
    let schemeMapping = [("coreioss", "https"), ("coreios", "http")]

    // MARK: - Public properties and methods

    init(api: APIService, startToken: String?, methods: [VerifyMethod]?, clientApp: ClientApp) {
        self.apiService = api
        self.startToken = startToken
        self.methods = methods
        self.clientApp = clientApp
    }

    var getURLRequest: URLRequest {
        let host = apiService.doh.getHumanVerificationV3Host()
        let token = "?token=\(startToken ?? "")"
        let methodsStrings = methods?.map { $0.method } ?? []
        let methods = "&methods=\(methodsStrings.joined(separator: ","))"
        let theme = "&theme=\(getTheme)"
        let locale = "&locale=\(getLocale)"
        let country = "&defaultCountry=\(getCountry)"
        let embed = "&embed=true"
        let vpn = clientApp == .vpn ? "&vpn=true" : ""
        let url = URL(string: "\(host)/\(token)\(methods)\(theme)\(locale)\(country)\(embed)\(vpn)")!
        let request = URLRequest(url: url)
        PMLog.info("\(request)")
        return request
    }
    
    func shouldRetryFailedLoading(host: String, error: Error, shouldReloadWebView: @escaping (Bool) -> Void) {
        let requestHeaders = apiService.doh.getHumanVerificationV3Headers()
        apiService.doh.handleErrorResolvingProxyDomainIfNeeded(host: host, requestHeaders: requestHeaders, sessionId: apiService.sessionUID, error: error, completion: shouldReloadWebView)
    }
    
    func setup(webViewConfiguration: WKWebViewConfiguration) {
        let requestInterceptor = AlternativeRoutingRequestInterceptor(
            headersGetter: apiService.doh.getHumanVerificationV3Headers,
            cookiesSynchronization: apiService.doh.synchronizeCookies(with:)
        ) { challenge, completionHandler in
            handleAuthenticationChallenge(
                didReceive: challenge,
                noTrustKit: PMAPIService.noTrustKit,
                trustKit: PMAPIService.trustKit,
                challengeCompletionHandler: completionHandler
            )
        }
        requestInterceptor.setup(webViewConfiguration: webViewConfiguration)
    }
    
    func finalToken(method: VerifyMethod, token: String, complete: @escaping SendVerificationCodeBlock) {
        self.token = token
        self.tokenMethod = method
        onVerificationCodeBlock?({ (res, error, finish) in
            complete(res, error, finish)
        })
    }
    
    func getToken() -> TokenType {
        return TokenType(verifyMethod: tokenMethod, token: token)
    }
    
    func interpretMessage(message: WKScriptMessage,
                          notificationMessage: ((NotificationType, String) -> Void)? = nil,
                          loadedMessage: (() -> Void)? = nil,
                          errorHandler: ((ResponseError, Bool) -> Void)? = nil,
                          completeHandler: ((VerifyMethod) -> Void)) {
        guard message.name == scriptName,
              let string = message.body as? String,
              let json = try? JSONSerialization.jsonObject(with: Data(string.utf8), options: []) as? [String: Any]
        else { return }
        guard let type = json["type"] as? String, let messageType = MessageType(rawValue: type) else { return }
        
        processMessage(type: messageType,
                       json: json,
                       notificationMessage: notificationMessage,
                       loadedMessage: loadedMessage,
                       errorHandler: errorHandler,
                       completeHandler: completeHandler)
    }
    
    // swiftlint:disable function_parameter_count
    private func processMessage(type: MessageType,
                                json: [String: Any],
                                notificationMessage: ((NotificationType, String) -> Void)?,
                                loadedMessage: (() -> Void)?,
                                errorHandler: ((ResponseError, Bool) -> Void)?,
                                completeHandler: ((VerifyMethod) -> Void)) {
        switch type {
        case .human_verification_success:
            guard let messageSuccess: MessageSuccess = decode(json: json) else { return }
            let method = VerifyMethod(string: messageSuccess.payload.type)
            finalToken(method: method, token: messageSuccess.payload.token) { res, responseError, verificationCodeBlockFinish in
                // if for some reason verification code is not accepted by the BE, send errorHandler to relaunch HV UI once again
                if res {
                    verificationCodeBlockFinish?()
                } else if let responseError = responseError {
                    errorHandler?(responseError, true)
                }
            }
            // messageSuccess is emitted by the Web core with validated verification code, then it's possible to send completeHandler to close HV UI
            completeHandler(method)
            
        case .notification:
            guard let messageNotification: MessageNotification = decode(json: json),
                  (messageNotification.payload.type == .success || messageNotification.payload.type == .error)
            else { return }
            notificationMessage?(messageNotification.payload.type, messageNotification.payload.text)
        case .loaded:
            loadedMessage?()
        case .close:
            let responseError = ResponseError(httpCode: nil, responseCode: APIErrorCode.humanVerificationEditEmail, userFacingMessage: "Human Verification edit email address", underlyingError: nil)
            errorHandler?(responseError, true)
        case .error:
            guard let messageError: MessageError = decode(json: json) else { return }
            let message = messageError.payload.message ?? CoreString._ad_delete_network_error
            let responseError = ResponseError(httpCode: nil, responseCode: messageError.payload.code, userFacingMessage: message, underlyingError: nil)
            errorHandler?(responseError, false)
        case .resize:
            break
        }
    }
    
    private func decode<T: Decodable>(json: [String: Any]) -> T? {
        guard let data = try? JSONSerialization.data(withJSONObject: json) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    private var getLocale: String {
        return Locale.current.identifier
    }
    
    private var getCountry: String {
        return Locale.current.regionCode ?? ""
    }
}

#if canImport(AppKit)
import AppKit
extension HumanVerifyV3ViewModel {
    
    public var isInDarkMode: Bool {
        guard #available(macOS 10.14, *) else { return false }
        return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
    
    private var getTheme: Int {
        if #available(macOS 10.14, *) {
            if isInDarkMode {
                return 1
            } else {
                return 2
            }
        } else {
            if clientApp == .vpn {
                return 1
            } else {
                return 0
            }
        }
    }
}
#elseif canImport(UIKit)
import UIKit
extension HumanVerifyV3ViewModel {
    private var getTheme: Int {
        if #available(iOS 13.0, *) {
            if let vc = UIApplication.shared.keyWindow?.rootViewController, vc.traitCollection.userInterfaceStyle == .dark {
                return 1
            } else {
                return 2
            }
        } else {
            if clientApp == .vpn {
                return 1
            } else {
                return 0
            }
        }
    }
}
#endif
