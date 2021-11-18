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

import Foundation
import class WebKit.WKWebView
import ProtonCore_Networking
import ProtonCore_Services

class RecaptchaViewModel: BaseTokenViewModel {

    // MARK: - Private properties

    var startToken: String?

    // MARK: - Public properties and methods

    init(api: APIService, startToken: String?) {
        super.init(api: api)
        self.startToken = startToken
        self.method = .captcha
        self.destination = ""
    }

    func getCaptchaURL() -> URL {
        let captchaHost = apiService.doh.getCaptchaHostUrl()
        return URL(string: "\(captchaHost)/core/v4/captcha?Token=\(startToken ?? "")&client=ios")!
    }

    func isStartVerifyPattern(urlString: String) -> Bool {
        return startVerifyPattern.contains(where: urlString.contains)
    }

    func isTermsAndPrivacyPattern(urlString: String) -> Bool {
        return termsAndPrivacyPatternForReCaptcha.contains(where: urlString.contains)
    }

    func isResultFalsePattern(urlString: String) -> Bool {
        return resultFalsePattern.contains(where: urlString.contains)
    }

    func isExpiredRecaptchaRes(urlString: String) -> Bool {
        return urlString.range(of: expiredRecaptchaRes) != nil
    }

    func isRecaptchaRes(urlString: String) -> Bool {
        return urlString.range(of: recaptchaRes) != nil
    }

    func getFinalToken(urlString: String) -> String? {
        return urlString.replacingOccurrences(of: recaptchaRes, with: "", options: NSString.CompareOptions.widthInsensitive, range: nil)
    }

    func isDocHeight(webView: WKWebView, completion: @escaping (Bool) -> Void) {
        webView.evaluateJavaScript(docHeight) { result, error in
            if result == nil {
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    // MARK: - Private properties

    private var startVerifyPattern: [String] {
        return ["https://www.google.com/recaptcha/api2/frame",
                ".com/fc/api/nojs",
                "fc/apps/canvas",
                "about:blank"]
    }

    private var termsAndPrivacyPatternForReCaptcha: [String] {
        return ["https://www.google.com/intl/en/policies/privacy",
                "https://www.google.com/intl/en/policies/terms"]
    }

    private var resultFalsePattern: [String] {
        return ["how-to-solve-"]
    }

    private var expiredRecaptchaRes: String {
        let captchaHost = apiService.doh.getCaptchaHostUrl()
        return "\(captchaHost)/core/v4/expired_recaptcha_response://"
    }

    private var recaptchaRes: String {
        let captchaHost = apiService.doh.getCaptchaHostUrl()
        return "\(captchaHost)/core/v4/recaptcha_response://"
    }

    private var docHeight = "document.body.scrollHeight;"
}
