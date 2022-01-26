//
//  RecaptchaViewModel.swift
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
        var host = apiService.doh.getHumanVerificationV3Host()
        if apiService.doh.isCurrentlyUsingProxyDomain {
            for (custom, original) in schemeMapping {
                host = host.replacingOccurrences(of: original, with: custom)
            }
        }
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
        apiService.doh.handleErrorResolvingProxyDomainIfNeeded(host: host, error: error, completion: shouldReloadWebView)
    }
    
    func setup(webViewConfiguration: WKWebViewConfiguration) {
        let requestInterceptor = AlternativeRoutingRequestInterceptor(doH: apiService.doh, schemeMapping: schemeMapping)
        for (custom, _) in schemeMapping {
            webViewConfiguration.setURLSchemeHandler(requestInterceptor, forURLScheme: custom)
        }
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

private final class AlternativeRoutingRequestInterceptor: NSObject, WKURLSchemeHandler, URLSessionDelegate {
    
    private enum RequestInterceptorError: Error {
        case noUrlInRequest
        case constructedUrlIsIncorrect
    }
    
    private let doH: DoHInterface
    private let schemeMapping: [(String, String)]
    
    init(doH: DoHInterface, schemeMapping: [(String, String)]) {
        self.doH = doH
        self.schemeMapping = schemeMapping
    }
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        var request = urlSchemeTask.request
        
        guard var urlString = request.url?.absoluteString else {
            urlSchemeTask.didFailWithError(RequestInterceptorError.noUrlInRequest)
            return
        }
        
        // Implements rewriting the request if alternative routing is on. Rewriting request means:
        // 1. Changing the custom scheme "coreios" in the request url to "http"
        // 2. Replacing the "-api" suffix appended to the first part of url host by captcha JS code.
        //    It's required because there is no proxy domain with -api suffix)
        // 3. Adding the appropriate proxying headers for all requests BUT to `/captcha`.
        //    The request for captcha is the API request that should go directly through proxy, so headers are removed.
        // 4. Changing the custom scheme "coreios" to "http" in the "Origin" header
        var apiRange: Range<String.Index>?
        for (custom, original) in schemeMapping where urlString.contains(custom) {
            urlString = urlString.replacingOccurrences(of: custom, with: original)
            if let range = urlString.range(of: "-api") {
                apiRange = range
                urlString = urlString.replacingCharacters(in: range, with: "")
            }
            let isCaptcha = urlString.contains("/captcha?")
            for (key, value) in doH.getHumanVerificationV3Headers() {
                request.setValue(isCaptcha ? nil : value, forHTTPHeaderField: key)
            }
            if let origin = request.value(forHTTPHeaderField: "Origin") {
                request.setValue(origin.replacingOccurrences(of: custom, with: original), forHTTPHeaderField: "Origin")
            }
            guard let url = URL(string: urlString) else {
                urlSchemeTask.didFailWithError(RequestInterceptorError.constructedUrlIsIncorrect)
                return
            }
            request.url = url
        }
        
        performRequest(request, apiRange, urlSchemeTask)
    }
    
    private func performRequest(_ request: URLRequest, _ apiRange: Range<String.Index>?, _ urlSchemeTask: WKURLSchemeTask) {
        guard let urlString = request.url?.absoluteString else {
            urlSchemeTask.didFailWithError(RequestInterceptorError.noUrlInRequest)
            return
        }
        PMLog.debug("request interceptor starts request to \(urlString) with X-PM-DoH-Host: \(request.allHTTPHeaderFields?["X-PM-DoH-Host"] ?? "")")
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpCookieAcceptPolicy = .always
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let response = response {
                self?.transformAndProcessResponse(response, apiRange, urlSchemeTask)
            }
            if let data = data {
                urlSchemeTask.didReceive(data)
            }
            if let error = error {
                urlSchemeTask.didFailWithError(error)
            } else {
                urlSchemeTask.didFinish()
            }
        }
        task.resume()
    }
    
    // Implements rewriting the response if alternative routing is on. Rewriting response means:
    // 1. Enabling the Content Security Policy for captcha with proxy domains by adding the proxy domains
    //    to frame-src. Both the original and `-api` variants are added. Also, if all "http" is allowed via frame-src,
    //    we add the custom scheme "coreios" there as well.
    //    The reason for adding to frame-src is that captcha is being shown in a frame and if CSP is not set up properly,
    //    the system blocks the loading of the frame even before our interceptor. We never have the chance to control it.
    // 2. Changing all the urls starting with "http" to "coreios" in the headers
    // 3. Adding back (if needed) the the "-api" suffix appended to the first part of url host by captcha JS code.
    // 4. Changing the "http" scheme back to the custom one "coreios" in the response url
    private func transformAndProcessResponse(_ response: URLResponse, _ apiRange: Range<String.Index>?, _ urlSchemeTask: WKURLSchemeTask) {
        guard let httpResponse = response as? HTTPURLResponse,
              var urlString = httpResponse.url?.absoluteString
        else {
            urlSchemeTask.didReceive(response)
            return
        }
        
        var headers: [String: String] = httpResponse.allHeaderFields as? [String: String] ?? [:]
        headers = headers.mapValues { (originalValue: String) -> String in
            var value = originalValue
            for (custom, original) in self.schemeMapping {
                value = value.replacingOccurrences(of: "\(original)://", with: "\(custom)://")
                if let range = value.range(of: "frame-src 'self' blob: "), let host = URL(string: urlString)?.host {
                    value.insert(contentsOf: "\(custom)://\(host) ", at: range.upperBound)
                    
                    if let index = host.firstIndex(of: ".") {
                        var hostWithAPI = host
                        hostWithAPI.insert(contentsOf: "-api", at: index)
                        value.insert(contentsOf: "\(custom)://\(hostWithAPI) ", at: range.upperBound)
                    }
                }
                
                [
                    "script-src",
                    "style-src",
                    "img-src",
                    "frame-src",
                    "connect-src",
                    "media-src"
                ] .forEach {
                    if let range = value.range(of: $0) {
                        value.insert(contentsOf: " \(custom):", at: range.upperBound)
                    }
                }
                
            }
            return value
        }
        
        if let apiRange = apiRange {
            urlString.insert(contentsOf: "-api", at: apiRange.lowerBound)
        }
        
        for (custom, original) in self.schemeMapping where urlString.contains(original) {
            urlString = urlString.replacingOccurrences(of: original, with: custom)
        }
        
        guard let url = URL(string: urlString),
              let newResponse = HTTPURLResponse(url: url, statusCode: httpResponse.statusCode, httpVersion: nil, headerFields: headers)
        else {
            urlSchemeTask.didReceive(response)
            return
        }
    
        urlSchemeTask.didReceive(newResponse)
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        let request = urlSchemeTask.request
        guard let urlString = request.url?.absoluteString else {
            urlSchemeTask.didFailWithError(RequestInterceptorError.noUrlInRequest)
            return
        }
        // we only log here and not cancel the url data task just for the simplicity of implementation
        PMLog.debug("request interceptor stops request to \(urlString) with X-PM-DoH-Host: \(request.allHTTPHeaderFields?["X-PM-DoH-Host"] ?? "")")
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        handleAuthenticationChallenge(
            didReceive: challenge,
            noTrustKit: PMAPIService.noTrustKit,
            trustKit: PMAPIService.trustKit,
            challengeCompletionHandler: completionHandler
        )
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
