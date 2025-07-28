//
// Copyright (c) 2025 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

enum L10n {
    static let autoRenewalNotice = LocalizedStringResource("Auto-renews at the same price and terms unless canceled", comment: "Notice at the bottom")
    static let chooseYourPlan = LocalizedStringResource("Choose your plan", comment: "Displayed above the plans")
    static let perMonth = LocalizedStringResource("/month", comment: "Displayed next to the monthly price")

    static func screenTitle(planName: String, entryPoint: UpsellScreenEntryPoint) -> LocalizedStringResource {
        switch entryPoint {
        case .autoDelete:
            .init("Automated trash removal", comment: "Title of the upsell page ")
        case .contactGroups:
            .init("Group your contacts", comment: "Title of the upsell page")
        case .folders, .labels:
            .init("Need more labels or folders?", comment: "Title of the upsell page")
        case .header:
            .init("Upgrade to \(planName)", comment: "Title of the upsell page")
        case .mobileSignature:
            .init("Personalize your signature", comment: "Title of the upsell page")
        case .scheduleSend:
            .init("Schedule now, send later", bundle: .module, comment: "Title of the upsell page")
        case .snooze:
            .init("Bad time for this email?", comment: "Title of the upsell page")
        }
    }

    static func screenSubtitle(planName: String, entryPoint: UpsellScreenEntryPoint) -> LocalizedStringResource {
        switch entryPoint {
        case .autoDelete:
            .init("Deletes spam and trash after 30 days. Get this and more with \(planName).", comment: "Subtitle of the upsell page")
        case .contactGroups:
            .init("Send group emails with ease. Enjoy this and more with \(planName).", comment: "Subtitle of the upsell page")
        case .folders, .labels:
            .init("Create all you need to stay organized. Get this and more with \(planName).", comment: "Subtitle of the upsell page")
        case .header:
            .init("To unlock more storage and premium features.", comment: "Subtitle of the upsell page")
        case .mobileSignature:
            .init("Make your mobile signature your own. Enjoy this and more with \(planName).", comment: "Subtitle of the upsell page")
        case .scheduleSend:
            .init("Customize when an email will be sent. Enjoy this and more with \(planName).", comment: "Subtitle of the upsell page")
        case .snooze:
            .init("Snooze it — and have it delivered later.  Enjoy this and more with \(planName).", comment: "Subtitle of the upsell page")
        }
    }

    enum Error {
        static let planNotFound = LocalizedStringResource("The requested plan could not be found.", comment: "Error message when fetching available plans fails")
    }

    enum PlanName {
        static let free = LocalizedStringResource("Free", comment: "Name of the free plan")
        static let plus = LocalizedStringResource("Plus", comment: "As in Mail Plus - short name for the plan")
    }

    enum Perk {
        static let storage = LocalizedStringResource("Storage", bundle: .module, comment: "Description of a feature of a paid subscription")
        static let emailAddresses = LocalizedStringResource("Email addresses", comment: "Description of a feature of a paid subscription")
        static let customEmailDomain = LocalizedStringResource("Custom email domain", comment: "Description of a feature of a paid subscription")
        static let accessToDesktopApp = LocalizedStringResource("Access to desktop app", comment: "Description of a feature of a paid subscription")
        static let unlimitedFoldersAndLabels = LocalizedStringResource("Unlimited folders and labels", comment: "Description of a feature of a paid subscription")
        static let priorityCustomerSupport = LocalizedStringResource("Priority customer support", comment: "Description of a feature of a paid subscription")
    }

    static func getPlan(named planName: String) -> LocalizedStringResource {
        .init("Get \(planName)", comment: "CTA button to purchase a plan (e.g. Get Mail Plus)")
    }
}
