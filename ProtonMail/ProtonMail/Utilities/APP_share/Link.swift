//
//  Link.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
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

import Foundation

enum Link {
    static let alternativeRouting = "https://proton.me/blog/anti-censorship-alternative-routing"
    static let unsubscribeInfo = "https://proton.me/support/knowledge-base/auto-unsubscribe"
    static let dmarcFailedInfo = "https://proton.me/support/knowledge-base/email-has-failed-its-domains-authentication-requirements-warning/"
    static let emailTrackerProtection = "https://proton.me/support/email-tracker-protection"
    static let encryptOutsideInfo = "https://proton.me/support/knowledge-base/encrypt-for-outside-users/"
    static let autoReplyInfo = "https://proton.me/support/knowledge-base/autoresponder/"
    static let protonvpn = "https://protonvpn.com"
    static let tor = "https://www.torproject.org"
    static let protonStatus = "https://protonstatus.com"
    static let supprotForm = "https://proton.me/support-form"
    static let protonTwitter = "https://twitter.com/ProtonMail"
    static let protonSupportMailTo = "mailto:support@protonmail.zendesk.com"
    static let encryptedSearchInfo = "https://proton.me/support/search-message-content"

    enum ReferralProgram {
        static let trackYourRewards = "https://account.proton.me/mail/referral"
        static let referralTermsAndConditions = "https://proton.me/support/referral-program"
    }
}
