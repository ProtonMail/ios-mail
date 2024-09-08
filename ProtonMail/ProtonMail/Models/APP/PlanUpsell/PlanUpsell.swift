// Copyright (c) 2024 Proton Technologies AG
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
import ProtonCorePayments
import ProtonCorePaymentsUI
import ProtonMailUI

public enum PlanUpsell: String, CaseIterable {
    case free
    case mail2022
    case drive2022
    case bundle2022
    case duo2024
    case family2022
    case visionary2022
    case mailpro2022
    case bundlepro2022
    case enterprise2022
    case mailbiz2024
    case bundlepro2024

    init?(planName: String) {
        self.init(rawValue: planName)
    }

    var perks: [UpsellPageModel.Perk] {
        switch self {
        case .mail2022:
            return [
                .init(icon: \.storage, description: String(format: L10n.PremiumPerks.nGBTotalStorage, 15)),
                .init(icon: \.gift, description: L10n.PremiumPerks.yearlyFreeStorageBonuses),
                .init(icon: \.envelopes, description: String(format: PUITranslations.plan_details_n_addresses.l10n, 10)),
                .init(icon: \.folders, description: PUITranslations._details_unlimited_folders_labels_filters.l10n),
                .init(icon: \.globe, description: L10n.PremiumPerks.yourOwnCustomEmailDomain),
                .init(icon: \.calendarGrid, description: L10n.PremiumPerks.calendarSharing),
                .init(icon: \.at, description: L10n.PremiumPerks.shortDomain),
                .init(icon: \.clockPaperPlane, description: L10n.PremiumPerks.customScheduleAndSnoozeTimes),
                .init(icon: \.tv, description: L10n.PremiumPerks.mailDesktopApp),
                .init(icon: \.lifeRing, description: PUITranslations._plan_details_priority_support.l10n)
            ]
        case .drive2022:
            return [
                .init(icon: \.storage, description: String(format: L10n.PremiumPerks.nGBTotalStorage, 200)),
                .init(icon: \.gift, description: L10n.PremiumPerks.yearlyFreeStorageBonuses),
                .init(icon: \.envelopes, description: L10n.PremiumPerks.versionHistory),
                .init(icon: \.lifeRing, description: PUITranslations._plan_details_priority_support.l10n)
            ]
        case .bundle2022:
            return [
                .init(icon: \.storage, description: String(format: L10n.PremiumPerks.nGBTotalStorage, 500)),
                .init(icon: \.gift, description: L10n.PremiumPerks.yearlyFreeStorageBonuses),
                .init(icon: \.shieldHalfFilled, description: L10n.PremiumPerks.sentinelProgram),
                .init(icon: \.lifeRing, description: PUITranslations._plan_details_priority_support.l10n),
                .init(icon: \.brandProtonMail, description: L10n.PremiumPerks.mailAndPremiumFeatures),
                .init(icon: \.brandProtonCalendar, description: L10n.PremiumPerks.calendarSharing),
                .init(icon: \.brandProtonDrive, description: L10n.PremiumPerks.driveWithVersionHistory),
                .init(icon: \.brandProtonPass, description: L10n.PremiumPerks.passWithUnlimitedAliases),
                .init(icon: \.brandProtonVpn, description: L10n.PremiumPerks.vpnHighSpeedServers)
            ]
        case .duo2024:
            return [
                .init(icon: \.storage, description: String(format: L10n.PremiumPerks.nTBTotalStorage, 1)),
                .init(icon: \.users, description: String(format: PUITranslations.plan_details_n_users.l10n, 2)),
                .init(icon: \.shieldHalfFilled, description: L10n.PremiumPerks.sentinelProgram),
                .init(icon: \.lifeRing, description: PUITranslations._plan_details_priority_support.l10n),
                .init(icon: \.brandProtonMail, description: L10n.PremiumPerks.mailAndPremiumFeatures),
                .init(icon: \.brandProtonCalendar, description: L10n.PremiumPerks.calendarSharing),
                .init(icon: \.brandProtonDrive, description: L10n.PremiumPerks.driveWithVersionHistory),
                .init(icon: \.brandProtonPass, description: L10n.PremiumPerks.passWithUnlimitedAliases),
                .init(icon: \.brandProtonVpn, description: L10n.PremiumPerks.vpnHighSpeedServers)
            ]
        case .family2022:
            return [
                .init(icon: \.storage, description: String(format: L10n.PremiumPerks.nTBTotalStorage, 3)),
                .init(icon: \.users, description: String(format: PUITranslations.plan_details_n_users.l10n, 6)),
                .init(icon: \.shieldHalfFilled, description: L10n.PremiumPerks.sentinelProgram),
                .init(icon: \.lifeRing, description: PUITranslations._plan_details_priority_support.l10n),
                .init(icon: \.brandProtonMail, description: L10n.PremiumPerks.mailAndPremiumFeatures),
                .init(icon: \.brandProtonCalendar, description: L10n.PremiumPerks.calendarSharing),
                .init(icon: \.brandProtonDrive, description: L10n.PremiumPerks.driveWithVersionHistory),
                .init(icon: \.brandProtonPass, description: L10n.PremiumPerks.passWithUnlimitedAliases),
                .init(icon: \.brandProtonVpn, description: L10n.PremiumPerks.vpnHighSpeedServers)
            ]
        case .visionary2022:
            return [
                .init(icon: \.storage, description: String(format: L10n.PremiumPerks.nTBTotalStorage, 6)),
                .init(icon: \.users, description: String(format: PUITranslations.plan_details_n_users.l10n, 6)),
                .init(icon: \.rocket, description: L10n.PremiumPerks.earlyAccess),
                .init(icon: \.shieldHalfFilled, description: L10n.PremiumPerks.sentinelProgram),
                .init(icon: \.brandProtonMail, description: L10n.PremiumPerks.mailAndPremiumFeatures),
                .init(icon: \.brandProtonCalendar, description: L10n.PremiumPerks.calendarSharing),
                .init(icon: \.brandProtonDrive, description: L10n.PremiumPerks.driveWithVersionHistory),
                .init(icon: \.brandProtonPass, description: L10n.PremiumPerks.passWithUnlimitedAliases),
                .init(icon: \.brandProtonVpn, description: L10n.PremiumPerks.vpnHighSpeedServers)
            ]
        case .mailpro2022:
            return [
                .init(icon: \.storage, description: String(format: L10n.PremiumPerks.nGBStoragePerUser, 15)),
                .init(icon: \.envelopes, description: String(format: L10n.PremiumPerks.nEmailAddressesPerUser, 10)),
                .init(icon: \.folders, description: L10n.PremiumPerks.unlimitedFoldersAndLabels),
                .init(icon: \.globe, description: String(format: L10n.PremiumPerks.nCustomEmailDmains, 10)),
                .init(icon: \.envelopeArrowUpAndRight, description: L10n.PremiumPerks.automaticEmailForwarding),
                .init(icon: \.calendarGrid, description: String(format: PUITranslations._details_n_calendars_per_user.l10n, 25)),
                .init(icon: \.calendarCheckmark, description: L10n.PremiumPerks.colleaguesAvailability),
                .init(icon: \.at, description: L10n.PremiumPerks.catchAllEmailAddress),
                .init(icon: \.tv, description: L10n.PremiumPerks.desktopAppAndEmailClientSupport),
                .init(icon: \.shieldHalfFilled, description: L10n.PremiumPerks.sentinelProgram),
                .init(icon: \.lifeRing, description: PUITranslations._plan_details_priority_support.l10n)
            ]
        case .mailbiz2024:
            return [
                .init(icon: \.storage, description: String(format: L10n.PremiumPerks.nGBStoragePerUser, 50)),
                .init(icon: \.envelopes, description: String(format: L10n.PremiumPerks.nEmailAddressesPerUser, 15)),
                .init(icon: \.folders, description: L10n.PremiumPerks.unlimitedFoldersAndLabels),
                .init(icon: \.globe, description: String(format: L10n.PremiumPerks.nCustomEmailDmains, 10)),
                .init(icon: \.envelopeArrowUpAndRight, description: L10n.PremiumPerks.automaticEmailForwarding),
                .init(icon: \.calendarGrid, description: String(format: PUITranslations._details_n_calendars_per_user.l10n, 25)),
                .init(icon: \.calendarCheckmark, description: L10n.PremiumPerks.colleaguesAvailability),
                .init(icon: \.at, description: L10n.PremiumPerks.catchAllEmailAddress),
                .init(icon: \.tv, description: L10n.PremiumPerks.desktopAppAndEmailClientSupport),
                .init(icon: \.shieldHalfFilled, description: L10n.PremiumPerks.sentinelProgram),
                .init(icon: \.lifeRing, description: PUITranslations._plan_details_priority_support.l10n)
            ]
        case .bundlepro2022, .bundlepro2024:
            return [
                .init(icon: \.storage, description: String(format: L10n.PremiumPerks.nGBStoragePerUser, 500)),
                .init(icon: \.envelopes, description: String(format: L10n.PremiumPerks.nEmailAddressesPerUser, 20)),
                .init(icon: \.globe, description: String(format: L10n.PremiumPerks.nCustomEmailDmains, 15)),
                .init(icon: \.users, description: String(format: PUITranslations._details_n_calendars_per_user.l10n, 25)),
                .init(icon: \.envelopeArrowUpAndRight, description: L10n.PremiumPerks.automaticEmailForwarding),
                .init(icon: \.brandProtonCalendar, description: L10n.PremiumPerks.calendarSharingAndAvailability),
                .init(icon: \.brandProtonDrive, description: L10n.PremiumPerks.driveWithVersionHistory),
                .init(icon: \.brandProtonPass, description: L10n.PremiumPerks.passWithUnlimitedAliases),
                .init(icon: \.brandProtonVpn, description: L10n.PremiumPerks.vpnHighSpeedServers),
                .init(icon: \.shieldHalfFilled, description: L10n.PremiumPerks.sentinelProgram),
                .init(icon: \.lifeRing, description: PUITranslations._plan_details_priority_support.l10n)
            ]
        default:
            return []
        }
    }
}
