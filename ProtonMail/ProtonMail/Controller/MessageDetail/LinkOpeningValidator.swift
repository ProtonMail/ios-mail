//
//  LinkOpeningValidator.swift
//  ProtonMail - Created on 26/04/2019.
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
    

import UIKit

protocol LinkOpeningValidator {
    var user: UserManager { get }
    func validateNotPhishing(_ url: URL, handler: @escaping (Bool)->Void)
}
extension LinkOpeningValidator {
    func validateNotPhishing(_ url: URL, handler: @escaping (Bool)->Void) {
        let userDataService = self.user.userService
        let userInfo = self.user.userInfo
        guard userInfo.linkConfirmation == .confirmationAlert else {
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
            userDataService.updateLinkConfirmation(auth: self.user.auth, user: self.user.userInfo, .openAtWill) { _, _, _ in /* nothing */ }
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
