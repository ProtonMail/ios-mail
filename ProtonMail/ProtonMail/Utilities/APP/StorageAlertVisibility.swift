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

enum StorageAlertVisibility: Equatable {
    case mail(CGFloat)
    case drive(CGFloat)
    case hidden

    static let bannerThreshold: CGFloat = 0.8
    static let fullThreshold: CGFloat = 0.98

    var mailboxBannerTitle: String {
        switch self {
        case .mail(let value) where value < Self.fullThreshold:
            return String(
                format: L10n.AlertBox.alertBoxMailPercentageText,
                storagePercentageString(storagePercentage: value)
            )
        case .drive(let value) where value < Self.fullThreshold:
            return String(
                format: L10n.AlertBox.alertBoxDrivePercentageText,
                storagePercentageString(storagePercentage: value)
            )
        case .mail:
            return L10n.AlertBox.alertBoxMailFullText
        case .drive:
            return L10n.AlertBox.alertBoxDriveFullText
        case .hidden:
            return ""
        }
    }

    var sideMenuCellTitle: String {
        switch self {
        case .mail(let value):
            return String(
                format: L10n.SideMenuStorageAlert.alertBoxMailTitle,
                storagePercentageString(storagePercentage: value)
            )
        case .drive(let value):
            return String(
                format: L10n.SideMenuStorageAlert.alertBoxDriveTitle,
                storagePercentageString(storagePercentage: value)
            )
        case .hidden:
            return ""
        }
    }

    private func storagePercentageString(storagePercentage: CGFloat) -> String {
        percentFormatter.string(from: NSNumber(value: storagePercentage)) ?? ""
    }

    private var percentFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.multiplier = 100
        formatter.maximumFractionDigits = 0
        return formatter
    }
}
