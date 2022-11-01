//
//  AlternativeRoutingRequestInterceptor.swift
//  ProtonCore-Doh - Created on 27/01/22.
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
import WebKit
import ProtonCore_Log

public final class AlternativeRoutingRequestInterceptor: NSObject, WKURLSchemeHandler, URLSessionDelegate {
    
    public static let schemeMapping: [(String, String)] = [("coreioss", "https"), ("coreios", "http")]
    
    private enum RequestInterceptorError: Error {
        case noUrlInRequest
        case constructedUrlIsIncorrect
    }
    
    private let headersGetter: () -> [String: String]
    private let cookiesSynchronization: (URLResponse?) -> Void
    private let onAuthenticationChallengeContinuation: (URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void
    
    public init(headersGetter: @escaping () -> [String: String],
                cookiesSynchronization: @escaping (URLResponse?) -> Void = { _ in },
                onAuthenticationChallengeContinuation: @escaping (URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void) {
        self.headersGetter = headersGetter
        self.cookiesSynchronization = cookiesSynchronization
        self.onAuthenticationChallengeContinuation = onAuthenticationChallengeContinuation
    }
    
    public func setup(webViewConfiguration: WKWebViewConfiguration) {
        for (custom, _) in AlternativeRoutingRequestInterceptor.schemeMapping {
            webViewConfiguration.setURLSchemeHandler(self, forURLScheme: custom)
        }
    }
    
    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        var request = urlSchemeTask.request
        
        guard var urlString = request.url?.absoluteString else {
            urlSchemeTask.didFailWithError(RequestInterceptorError.noUrlInRequest)
            return
        }
        
        // Implements rewriting the request if alternative routing is on. Rewriting request means:
        // 1. Changing the custom scheme "coreios" in the request url to "http"
        // 2. Replacing the "-api" suffix appended to the first part of url host by captcha JS code.
        //    It's required because there is no proxy domain with -api suffix)
        //    NOTE: It's applicable only to human verification but it doesn't influence other usecases so we can leave single implemention.
        // 3. Adding the appropriate proxying headers for all requests BUT to `/captcha`.
        //    The request for captcha is the API request that should go directly through proxy, so headers are removed.
        //    NOTE: It's applicable only to human verification but it doesn't influence other usecases so we can leave single implemention.
        // 4. Changing the custom scheme "coreios" to "http" in the "Origin" header
        var apiRange: Range<String.Index>?
        for (custom, original) in AlternativeRoutingRequestInterceptor.schemeMapping where urlString.contains(custom) {
            urlString = urlString.replacingOccurrences(of: custom, with: original)
            if let range = urlString.range(of: "-api") {
                apiRange = range
                urlString = urlString.replacingCharacters(in: range, with: "")
            }
            let isCaptcha = urlString.contains("/captcha?")
            for (key, value) in headersGetter() {
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
        PMLog.debug("request interceptor starts request to \(urlString) with \(DoHConstants.dohHostHeader): \(request.allHTTPHeaderFields?[DoHConstants.dohHostHeader] ?? "")")
        
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
    //    NOTE: It's applicable only to human verification but it doesn't influence other usecases so we can leave single implemention.
    // 2. Changing all the urls starting with "http" to "coreios" in the headers
    // 3. Adding back (if needed) the the "-api" suffix appended to the first part of url host by captcha JS code.
    //    NOTE: It's applicable only to human verification but it doesn't influence other usecases so we can leave single implemention.
    // 4. Changing the "http" scheme back to the custom one "coreios" in the response url
    public func transformAndProcessResponse(_ response: URLResponse, _ apiRange: Range<String.Index>?, _ urlSchemeTask: WKURLSchemeTask) {
        cookiesSynchronization(response)
        guard let httpResponse = response as? HTTPURLResponse,
              var urlString = httpResponse.url?.absoluteString
        else {
            urlSchemeTask.didReceive(response)
            return
        }
        
        var headers: [String: String] = httpResponse.allHeaderFields as? [String: String] ?? [:]
        headers = headers.mapValues { (originalValue: String) -> String in
            var value = originalValue
            for (custom, original) in AlternativeRoutingRequestInterceptor.schemeMapping {
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
                    "font-src",
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
        
        for (custom, original) in AlternativeRoutingRequestInterceptor.schemeMapping where urlString.contains(original) {
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
    
    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        let request = urlSchemeTask.request
        guard let urlString = request.url?.absoluteString else {
            urlSchemeTask.didFailWithError(RequestInterceptorError.noUrlInRequest)
            return
        }
        // we only log here and not cancel the url data task just for the simplicity of implementation
        PMLog.debug("request interceptor stops request to \(urlString) with \(DoHConstants.dohHostHeader): \(request.allHTTPHeaderFields?[DoHConstants.dohHostHeader] ?? "")")
    }
    
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        onAuthenticationChallengeContinuation(challenge, completionHandler)
    }
}
