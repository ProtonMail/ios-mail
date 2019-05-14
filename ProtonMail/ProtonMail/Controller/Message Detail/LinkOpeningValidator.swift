//
//  LinkOpeningValidator.swift
//  ProtonMail - Created on 26/04/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import UIKit

protocol LinkOpeningValidator {
    func validateNotPhishing(_ url: URL, handler: @escaping (Bool)->Void)
}
extension LinkOpeningValidator {
    func validateNotPhishing(_ url: URL, handler: @escaping (Bool)->Void) {
        guard userCachedStatus.linkOpeningMode == .confirmationAlert else {
            handler(true)
            return
        }
        
        guard url.isOwnedByProton == false else {
            handler(true)
            return
        }
        
        var tail = url.absoluteString.dropFirst(60)
        tail = tail.isEmpty ? "" : ("\n...\n" + tail.suffix(40))
        let shortLink = url.absoluteString.prefix(60) + tail
        
        let alert = UIAlertController(title: LocalString._about_to_open_link,
                                      message: String(shortLink),
                                      preferredStyle: .alert)
        let proceed = UIAlertAction(title: LocalString._genernal_continue, style: .destructive) { _ in
            handler(true)
        }
        let doNotShowAgain = UIAlertAction(title: LocalString._genernal_continue_and_dont_ask_again, style: .destructive) { _ in
            userCachedStatus.linkOpeningMode = .openAtWill
            handler(true)
        }
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel) { _ in
            handler(false)
        }
        [proceed, doNotShowAgain, cancel].forEach(alert.addAction)

        // will deliver to the topmost view controller in responder chain
        UIApplication.shared.sendAction(#selector(UIViewController.present(_:animated:completion:)), to: nil, from: alert, for: nil)
    }
}

extension URL {
    var isOwnedByProton: Bool {
        guard let host = self.host?.lowercased() else { return false }
        return ["protonmail.com",
                "protonmail.ch",
                "protonvpn.com",
                "protonstatus.com",
                "gdpr.eu",
                "protonvpn.net",
                "pm.me",
                "protonirockerxow.onion",
                "mail.protonmail.com",
                "account.protonvpn.com",].contains(host)
    }
}
