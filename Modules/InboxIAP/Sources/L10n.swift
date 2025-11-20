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
import StoreKit
import proton_app_uniffi

enum L10n {
    static let autoRenewalNotice = LocalizedStringResource("Auto-renews at the same price and terms unless canceled", bundle: .module, comment: "Notice at the bottom")
    static let bestValue = LocalizedStringResource("Best value", bundle: .module, comment: "Badge next to the plan name in the upsell screen")
    static let chooseYourPlan = LocalizedStringResource("Choose your plan", bundle: .module, comment: "Displayed above the plans in the upsell modal")
    static let chooseSubscription = LocalizedStringResource("Choose subscription", bundle: .module, comment: "Displayed above the plans in the upsell modal")
    static let continueWithFreePlan = LocalizedStringResource("Continue with Free Plan", bundle: .module, comment: "The option to exit the upsell modal")
    static let perMonth = LocalizedStringResource("/month", bundle: .module, comment: "Displayed next to the monthly price")
    static let showLess = LocalizedStringResource("Show less", bundle: .module, comment: "Button to collapse a list")
    static let showMore = LocalizedStringResource("Show more", bundle: .module, comment: "Button to expand a list")

    static func screenTitle(planName: String, entryPoint: UpsellEntryPoint) -> LocalizedStringResource {
        switch entryPoint {
        case .autoDeleteMessages:
            .init("Automated trash removal", bundle: .module, comment: "Title of the upsell page ")
        case .contactGroups:
            .init("Group your contacts", bundle: .module, comment: "Title of the upsell page")
        case .dollarPromo, .mailboxTopBarPromo:
            fatalError("This entry point is not used")
        case .foldersCreation, .labelsCreation:
            .init("Need more labels or folders?", bundle: .module, comment: "Title of the upsell page")
        case .mailboxTopBar, .navbarUpsell:
            .init("Upgrade to \(planName)", bundle: .module, comment: "Title of the upsell page")
        case .mobileSignatureEdit:
            .init("Personalize your signature", bundle: .module, comment: "Title of the upsell page")
        case .postOnboarding:
            fatalError("Onboarding upsell does not have a title")
        case .scheduleSend:
            .init("Schedule now, send later", bundle: .module, comment: "Title of the upsell page")
        case .snooze:
            .init("Bad time for this email?", bundle: .module, comment: "Title of the upsell page")
        }
    }

    static func screenSubtitle(planName: String, entryPoint: UpsellEntryPoint) -> LocalizedStringResource {
        switch entryPoint {
        case .autoDeleteMessages:
            .init("Deletes spam and trash after 30 days. Get this and more with \(planName).", bundle: .module, comment: "Subtitle of the upsell page")
        case .contactGroups:
            .init("Send group emails with ease. Enjoy this and more with \(planName).", bundle: .module, comment: "Subtitle of the upsell page")
        case .dollarPromo, .mailboxTopBarPromo:
            fatalError("This entry point is not used")
        case .foldersCreation, .labelsCreation:
            .init("Create all you need to stay organized. Get this and more with \(planName).", bundle: .module, comment: "Subtitle of the upsell page")
        case .mailboxTopBar, .navbarUpsell:
            .init("To unlock more storage and premium features.", bundle: .module, comment: "Subtitle of the upsell page")
        case .mobileSignatureEdit:
            .init("Make your mobile signature your own. Enjoy this and more with \(planName).", bundle: .module, comment: "Subtitle of the upsell page")
        case .postOnboarding:
            fatalError("Onboarding upsell does not have a subtitle")
        case .scheduleSend:
            .init("Customize when an email will be sent. Enjoy this and more with \(planName).", bundle: .module, comment: "Subtitle of the upsell page")
        case .snooze:
            .init("Snooze it — and have it delivered later.  Enjoy this and more with \(planName).", bundle: .module, comment: "Subtitle of the upsell page")
        }
    }

    static func payAnnuallyAndSave(amount: String) -> LocalizedStringResource {
        .init("Pay annually and save \(amount)", bundle: .module, comment: "Shown when selecting the yearly billing cycle")
    }

    static func onlyXPerMonth(_ amount: String) -> LocalizedStringResource {
        .init("only \(amount) /month", bundle: .module, comment: "Shown next to the discounted monthly price")
    }

    enum BillingCycle {
        static let monthly = LocalizedStringResource("Monthly", bundle: .module, comment: "Refers to billing cycle")
        static let yearlyNoDiscount = LocalizedStringResource("Yearly", bundle: .module, comment: "Refers to billing cycle")

        static func yearly(discount: Int) -> LocalizedStringResource {
            .init("Yearly (\(discount)% OFF)", bundle: .module, comment: "Refers to billing cycle, with discount compared to the monthly cycle")
        }
    }

    enum Error {
        static let planNotFound = LocalizedStringResource("The requested plan could not be found.", bundle: .module, comment: "Error message when fetching available plans fails")
    }

    enum PlanName {
        static let free = LocalizedStringResource("Free", bundle: .module, comment: "Name of the free plan")
        static let plus = LocalizedStringResource("Plus", bundle: .module, comment: "As in Mail Plus - short name for the plan")
    }

    enum Perk {
        static let storage = LocalizedStringResource("Storage", bundle: .module, comment: "Description of a feature of a paid subscription")
        static let emailAddresses = LocalizedStringResource("Email addresses", bundle: .module, comment: "Description of a feature of a paid subscription")
        static let customEmailDomain = LocalizedStringResource("Custom email domain", bundle: .module, comment: "Description of a feature of a paid subscription")
        static let accessToDesktopApp = LocalizedStringResource("Access to desktop app", bundle: .module, comment: "Description of a feature of a paid subscription")
        static let unlimitedFoldersAndLabels = LocalizedStringResource("Unlimited folders and labels", bundle: .module, comment: "Description of a feature of a paid subscription")
        static let priorityCustomerSupport = LocalizedStringResource("Priority customer support", bundle: .module, comment: "Description of a feature of a paid subscription")

        static func amountOfStorage(gigabytes: Double) -> LocalizedStringResource {
            let measurement = Measurement<UnitInformationStorage>(value: gigabytes, unit: .gigabytes)
            return .init("\(measurement.formatted()) storage", bundle: .module, comment: "Amount of storage space available in a given plan, for example: 1 GB storage")
        }

        static func numberOfEmailAddresses(_ amount: UInt) -> LocalizedStringResource {
            .init("\(amount) email addresses", bundle: .module, comment: "Number of email addresses available in a given plan")
        }
    }

    static func getPlan(named planName: String) -> LocalizedStringResource {
        .init("Get \(planName)", bundle: .module, comment: "CTA button to purchase a plan (e.g. Get Mail Plus)")
    }

    static func discountRenewalNotice(renewalPrice: String, period: Product.SubscriptionPeriod.Unit) -> LocalizedStringResource {
        .init(
            "Discounts are based on standard monthly pricing. Auto-renews at \(renewalPrice) /\(period.localizedDescription.lowercased()) until canceled.",
            bundle: .module,
            comment: "Notice at the bottom of the upsell page"
        )
    }
}

private extension LocalizedStringResource.BundleDescription {
    static var module: Self {
        .atURL(Bundle.module.bundleURL)
    }
}
