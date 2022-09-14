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

import UIKit
import ProtonCore_Doh
import ProtonCore_UIFoundations
import ProtonCore_CoreTranslation

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
                return CoreString._allow_alternative_routing
            case .noInternetNotes:
                return CoreString._no_internet_connection
            case .ispNotes:
                return CoreString._isp_problem
            case .blockNotes:
                return CoreString._gov_block
            case .antivirusNotes:
                return CoreString._antivirus_interference
            case .firewallNotes:
                return CoreString._firewall_interference
            case .downtimeNotes:
                return CoreString._proton_is_down
            case .otherNotes:
                return CoreString._no_solution
            }
        }
        
        var attributedString: NSMutableAttributedString {
            let caption1 = UIFont.preferredFont(forTextStyle: .caption1)
            switch self {
            case .allowSwitch:
                let holder = CoreString._allow_alternative_routing_description
                let learnMore = CoreString._allow_alternative_routing_action_title
                let full = String.localizedStringWithFormat(holder, learnMore)
                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                attributedString.addHyperLink(subString: learnMore, link: ExternalLink.alternativeRouting)
                return attributedString
                
            case .noInternetNotes:
                let full = CoreString._no_internet_connection_description
                let attributedString = full.buildAttributedString(font: UIFont.preferredFont(forTextStyle: .caption1), color: ColorProvider.TextWeak)
                return attributedString
                
            case .ispNotes:
                let holder = CoreString._isp_problem_description
                let field1 = "ProtonVPN"
                let field2 = "Tor"
                let full = String.localizedStringWithFormat(holder, field1, field2)
                
                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                attributedString.addHyperLinks(hyperlinks: [field1: ExternalLink.protonvpn,
                                                            field2: ExternalLink.tor])
                return attributedString
                
            case .blockNotes:
                let holder = CoreString._gov_block_description
                let field1 = "ProtonVPN"
                let field2 = "Tor"
                let full = String.localizedStringWithFormat(holder, field1, field2)
                
                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                attributedString.addHyperLinks(hyperlinks: [field1: ExternalLink.protonvpn,
                                                            field2: ExternalLink.tor])
                return attributedString
                
            case .antivirusNotes:
                let full = CoreString._antivirus_interference_description
                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                return attributedString
                
            case .firewallNotes:
                let full = CoreString._firewall_interference_description
                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                return attributedString
                
            case .downtimeNotes:
                let holder = CoreString._proton_is_down_description
                let field1 = CoreString._proton_is_down_action_title
                let full = String.localizedStringWithFormat(holder, field1)
                
                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                attributedString.addHyperLink(subString: field1, link: ExternalLink.protonStatus)
                return attributedString
                
            case .otherNotes:
                let holder = CoreString._no_solution_description
                let field1 = CoreString._troubleshooting_support_from
                let field2 = CoreString._troubleshooting_email_title
                let field3 = CoreString._troubleshooting_twitter_title
                let full = String.localizedStringWithFormat(holder, field1, field2, field3)
                let attributedString = full.buildAttributedString(font: caption1, color: ColorProvider.TextWeak)
                
                attributedString.addHyperLinks(hyperlinks: [field1: ExternalLink.supprotForm,
                                                            field2: ExternalLink.protonSupportMailTo,
                                                            field3: ExternalLink.protonTwitter])
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
    
    let title = CoreString._troubleshooting_title
}
