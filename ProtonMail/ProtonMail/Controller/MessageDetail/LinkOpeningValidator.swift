//
//  LinkOpeningValidator.swift
//  Proton Mail - Created on 26/04/2019.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_DataModel

protocol LinkOpeningValidator {
    var linkConfirmation: LinkOpeningMode { get }

    func shouldOpenPhishingAlert(_ url: URL, isFromPhishingMsg: Bool) -> Bool
    func generatePhishingAlertContent(_ url: URL, isFromPhishingMsg: Bool) -> (String, String)
}

extension LinkOpeningValidator {
    func shouldOpenPhishingAlert(_ url: URL, isFromPhishingMsg: Bool) -> Bool {
        guard linkConfirmation == .confirmationAlert || isFromPhishingMsg == true else {
            return false
        }

        guard url.isOwnedByProton == false else {
            return false
        }
        return true
    }

    func generatePhishingAlertContent(_ url: URL, isFromPhishingMsg: Bool) -> (String, String) {
        var tail = url.absoluteString.dropFirst(60)
        tail = tail.isEmpty ? "" : ("\n...\n" + tail.suffix(40))
        let shortLink = url.absoluteString.prefix(60) + tail

        if isFromPhishingMsg {
            let msg = String(format: LocalString._spam_open_link_content, String(shortLink))
            return (LocalString._spam_open_link_title, msg)
        } else {
            return (LocalString._about_to_open_link, String(shortLink))
        }
    }
}

extension URL {
    var isOwnedByProton: Bool {
        guard let host = host?.lowercased() else { return false }
        let protons = ["proton.me",
                       "protonmail.com",
                       "protonmail.ch",
                       "protonvpn.com",
                       "protonstatus.com",
                       "gdpr.eu",
                       "protonvpn.net",
                       "pm.me",
                       "protonirockerxow.onion"]
        for domain in protons {
            if host.hasSuffix(domain) { return true }
        }
        return false
    }
}
