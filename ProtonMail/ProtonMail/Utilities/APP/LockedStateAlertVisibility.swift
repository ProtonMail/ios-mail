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
import ProtonCoreDataModel

enum LockedStateAlertVisibility: Equatable {
    case mail
    case drive
    case storageFull
    case orgIssueForPrimaryAdmin
    case orgIssueForMember
    case hidden

    init(lockedFlags: LockedFlags) {
        self = .hidden

        if lockedFlags.contains(.orgIssueForPrimaryAdmin) {
            self = .orgIssueForPrimaryAdmin
        } else if lockedFlags.contains(.orgIssueForMember) {
            self = .orgIssueForMember
        } else if lockedFlags.contains(.storageExceeded) {
            self = .storageFull
        } else if lockedFlags.contains(.mailStorageExceeded) {
            self = .mail
        } else if lockedFlags.contains(.driveStorageExceeded) {
            self = .drive
        }
    }

    var mailboxBannerTitle: String? {
        switch self {
        case .mail:
            return L10n.LockedStateAlertBox.alertBoxMailFullText
        case .drive:
            return L10n.LockedStateAlertBox.alertBoxDriveFullText
        case .storageFull:
            return L10n.LockedStateAlertBox.alertBoxStorageFullText
        case .orgIssueForPrimaryAdmin:
            return L10n.LockedStateAlertBox.alertBoxSubscriptionEndedText
        case .orgIssueForMember:
            return L10n.LockedStateAlertBox.alertBoxAccountAtRiskText
        case .hidden:
            return nil
        }
    }

    var mailboxBannerDescription: String? {
        switch self {
        case .mail, .storageFull:
            return L10n.LockedStateAlertBox.alertBoxMailFullDescription
        case .drive:
            return L10n.LockedStateAlertBox.alertBoxDriveFullDescription
        case .orgIssueForPrimaryAdmin:
            return L10n.LockedStateAlertBox.alertBoxDescriptionForPrimaryAdmin
        case .orgIssueForMember:
            return L10n.LockedStateAlertBox.alertBoxDescriptionForOrgMember
        case .hidden:
            return nil
        }
    }

    var mailBoxBannerButtonTitle: String? {
        switch self {
        case .orgIssueForPrimaryAdmin:
            return L10n.LockedStateAlertBox.alertBoxButtonTitleForPrimaryAdmin
        case .orgIssueForMember:
            return L10n.LockedStateAlertBox.alertBoxButtonTitleForOrgMember
        case .hidden:
            return nil
        default:
            return L10n.LockedStateAlertBox.alertBoxDefaultButtonTitle
        }
    }

    var mailBoxBannerButtonUrl: String? {
        switch self {
        case .orgIssueForMember:
            return "https://proton.me/support/free-plan-limits"
        case .hidden:
            return nil
        default:
            return "https://account.proton.me/mail/dashboard"
        }
    }
}
