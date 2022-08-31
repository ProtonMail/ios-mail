//
//  SettingsViewModel.swift
//  Proton Mail - Created on 12/12/18.
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

import ProtonCore_Doh
import ProtonCore_UIFoundations
import UIKit

struct NetworkTroubleShootViewModel {

    private(set) var doh: DohStatusProtocol
    private(set) var dohSetting: DohCacheProtocol

    init(doh: DohStatusProtocol = DoHMail.default, dohSetting: DohCacheProtocol = userCachedStatus) {
        self.doh = doh
        self.dohSetting = dohSetting
    }

    var dohStatus: DoHStatus {
        get {
            return doh.status
        }
        set {
            doh.status = newValue
            dohSetting.isDohOn = newValue == .on
        }
    }

    enum Item: Int {
        case allowSwitch = 0
        case noInternetNotes = 1
        case ispNotes = 2
        case blockNotes = 3
        case antivirusNotes = 4
        case firewallNotes = 5
        case downtimeNotes = 6
        case otherNotes = 7

        var top: String {
            switch self {
            case .allowSwitch:
                return LocalString._allow_alternative_routing
            case .noInternetNotes:
                return LocalString._no_internet_connection
            case .ispNotes:
                return LocalString._isp_problem
            case .blockNotes:
                return LocalString._gov_block
            case .antivirusNotes:
                return LocalString._antivirus_interference
            case .firewallNotes:
                return LocalString._firewall_interference
            case .downtimeNotes:
                return LocalString._proton_is_down
            case .otherNotes:
                return LocalString._no_solution
            }
        }

        var attributedString: NSMutableAttributedString {
            let foregroundColor: UIColor = ColorProvider.TextWeak
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .caption1),
                .foregroundColor: foregroundColor
            ]

            let output: NSMutableAttributedString
            switch self {
            case .allowSwitch:
                let holder = LocalString._allow_alternative_routing_description
                let learnMore = LocalString._allow_alternative_routing_action_title

                let full = String.localizedStringWithFormat(holder, learnMore)
                output = NSMutableAttributedString(string: full, attributes: attributes)
                if let subrange = full.range(of: learnMore) {
                    let nsRange = NSRange(subrange, in: full)
                    output.addAttribute(.link,
                                                  value: Link.alternativeRouting,
                                                  range: nsRange)
                }

            case .noInternetNotes:
                let full = LocalString._no_internet_connection_description
                output = NSMutableAttributedString(string: full, attributes: attributes)

            case .ispNotes:
                let holder = LocalString._isp_problem_description
                let field1 = "ProtonVPN"
                let field2 = "Tor"

                let full = String.localizedStringWithFormat(holder, field1, field2)
                output = NSMutableAttributedString(string: full, attributes: attributes)
                if let subrange = full.range(of: field1) {
                    let nsRange = NSRange(subrange, in: full)
                    output.addAttribute(.link, value: Link.protonvpn, range: nsRange)
                }
                if let subrange = full.range(of: field2) {
                    let nsRange = NSRange(subrange, in: full)
                    output.addAttribute(.link, value: Link.tor, range: nsRange)
                }

            case .blockNotes:
                let holder = LocalString._gov_block_description
                let field1 = "ProtonVPN"
                let field2 = "Tor"

                let full = String.localizedStringWithFormat(holder, field1, field2)
                output = NSMutableAttributedString(string: full, attributes: attributes)
                if let subrange = full.range(of: field1) {
                    let nsRange = NSRange(subrange, in: full)
                    output.addAttribute(.link, value: Link.protonvpn, range: nsRange)
                }
                if let subrange = full.range(of: field2) {
                    let nsRange = NSRange(subrange, in: full)
                    output.addAttribute(.link, value: Link.tor, range: nsRange)
                }

            case .antivirusNotes:
                let full = LocalString._antivirus_interference_description
                output = NSMutableAttributedString(string: full, attributes: attributes)

            case .firewallNotes:
                let full = LocalString._firewall_interference_description
                output = NSMutableAttributedString(string: full, attributes: attributes)

            case .downtimeNotes:
                let holder = LocalString._proton_is_down_description
                let field1 = LocalString._proton_is_down_action_title
                let full = String.localizedStringWithFormat(holder, field1)
                output = NSMutableAttributedString(string: full, attributes: attributes)
                if let subrange = full.range(of: field1) {
                    let nsRange = NSRange(subrange, in: full)
                    output.addAttributes([.link: Link.protonStatus], range: nsRange)
                }

            case .otherNotes:
                let holder = LocalString._no_solution_description
                let field1 = "support form"
                let field2 = "email"
                let field3 = "Twitter"

                let full = String.localizedStringWithFormat(holder, field1, field2, field3)
                output = NSMutableAttributedString(string: full, attributes: attributes)
                if let subrange = full.range(of: field1) {
                    let nsRange = NSRange(subrange, in: full)
                    output.addAttributes([.link: Link.supprotForm], range: nsRange)
                }
                if let subrange = full.range(of: field2) {
                    let nsRange = NSRange(subrange, in: full)
                    output.addAttributes([.link: Link.protonSupportMailTo], range: nsRange)
                }
                if let subrange = full.range(of: field3) {
                    let nsRange = NSRange(subrange, in: full)
                    output.addAttributes([.link: Link.protonTwitter], range: nsRange)
                }
            }
            return output
        }
    }

    let items: [Item] = [
        .allowSwitch,
        .noInternetNotes,
        .ispNotes,
        .blockNotes,
        .antivirusNotes,
        .firewallNotes,
        .downtimeNotes,
        .otherNotes
    ]

    let title = LocalString._troubleshooting_title
}
