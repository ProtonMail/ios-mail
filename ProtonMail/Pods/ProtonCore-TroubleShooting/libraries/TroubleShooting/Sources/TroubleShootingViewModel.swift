//
//  TroubleShootingViewModel.swift
//  ProtonCore-TroubleShooting - Created on 08/20/2020
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
//

#if os(iOS)

import UIKit
import ProtonCoreDoh
import ProtonCoreUIFoundations

/// use to read&update doh instance
public protocol DohStatusProtocol {
    var status: DoHStatus { get set }
}

public struct TroubleShootingViewModel {
    private(set) var doh: DohStatusProtocol
    public init(doh: DohStatusProtocol) {
        self.doh = doh
    }

    var dohStatus: DoHStatus {
        get {
            return doh.status
        }
        set {
            doh.status = newValue
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
                return TSTranslation._allow_alternative_routing.l10n
            case .noInternetNotes:
                return TSTranslation._no_internet_connection.l10n
            case .ispNotes:
                return TSTranslation._isp_problem.l10n
            case .blockNotes:
                return TSTranslation._gov_block.l10n
            case .antivirusNotes:
                return TSTranslation._antivirus_interference.l10n
            case .firewallNotes:
                return TSTranslation._firewall_interference.l10n
            case .downtimeNotes:
                return TSTranslation._proton_is_down.l10n
            case .otherNotes:
                return TSTranslation._no_solution.l10n
            }
        }

        var attributedString: NSMutableAttributedString {
            let caption1 = UIFont.preferredFont(forTextStyle: .caption1)
            switch self {
            case .allowSwitch:
                let holder = TSTranslation._allow_alternative_routing_description.l10n
                let learnMore = TSTranslation._allow_alternative_routing_action_title.l10n
                let full = String.localizedStringWithFormat(holder, learnMore)
                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                attributedString.addHyperLink(subString: learnMore, link: ExternalLink.alternativeRouting)
                return attributedString

            case .noInternetNotes:
                let full = TSTranslation._no_internet_connection_description.l10n
                let attributedString = full.buildAttributedString(font: UIFont.preferredFont(forTextStyle: .caption1), color: ColorProvider.TextWeak)
                return attributedString

            case .ispNotes:
                let holder = TSTranslation._isp_problem_description.l10n
                let field1 = "ProtonVPN"
                let field2 = "Tor"
                let full = String.localizedStringWithFormat(holder, field1, field2)

                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                attributedString.addHyperLinks(hyperlinks: [field1: ExternalLink.protonvpn,
                                                            field2: ExternalLink.tor])
                return attributedString

            case .blockNotes:
                let holder = TSTranslation._gov_block_description.l10n
                let field1 = "ProtonVPN"
                let field2 = "Tor"
                let full = String.localizedStringWithFormat(holder, field1, field2)

                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                attributedString.addHyperLinks(hyperlinks: [field1: ExternalLink.protonvpn,
                                                            field2: ExternalLink.tor])
                return attributedString

            case .antivirusNotes:
                let full = TSTranslation._antivirus_interference_description.l10n
                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                return attributedString

            case .firewallNotes:
                let full = TSTranslation._firewall_interference_description.l10n
                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                return attributedString

            case .downtimeNotes:
                let holder = TSTranslation._proton_is_down_description.l10n
                let field1 = TSTranslation._proton_is_down_action_title.l10n
                let full = String.localizedStringWithFormat(holder, field1)

                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                attributedString.addHyperLink(subString: field1, link: ExternalLink.protonStatus)
                return attributedString

            case .otherNotes:
                let noSolutionDescription = TSTranslation._no_solution_description.l10n
                let supportForm = TSTranslation._troubleshooting_support_from.l10n
                let email = TSTranslation._troubleshooting_email_title.l10n
                let twitter = TSTranslation._troubleshooting_twitter_title.l10n
                let full = String.localizedStringWithFormat(noSolutionDescription, supportForm, email, twitter)
                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)

                attributedString.addHyperLinks(hyperlinks: [supportForm: ExternalLink.supportForm,
                                                            email: ExternalLink.protonSupportMailTo,
                                                            twitter: ExternalLink.protonTwitter])
                return attributedString
            }
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

    let title = TSTranslation._troubleshooting_title.l10n
}

#endif
