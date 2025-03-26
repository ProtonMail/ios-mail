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

import ProtonCorePayments
import ProtonMailUI

final class UpsellTelemetryReporter {
    typealias Dependencies = AnyObject & HasPlanService & HasTelemetryServiceProtocol & HasUserManager

    private unowned let dependencies: Dependencies

    private var plansDataSource: PlansDataSourceProtocol? {
        switch dependencies.planService {
        case .left:
            return nil
        case .right(let pdsp):
            return pdsp
        }
    }

    private var entryPoint: UpsellPageEntryPoint?
    private var planBeforeUpgrade: String?
    private var upsellPageVariant: UpsellPageModel.Variant?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func prepare(entryPoint: UpsellPageEntryPoint, upsellPageVariant: UpsellPageModel.Variant) {
        self.entryPoint = entryPoint
        planBeforeUpgrade = plansDataSource?.currentPlan?.subscriptions.compactMap(\.name).first ?? "free"
        self.upsellPageVariant = upsellPageVariant
    }

    func upsellPageDisplayed() async {
        let dimensions = makeDimensions()
        let event = makeEvent(name: .upsellButtonTapped, dimensions: dimensions)
        await dependencies.telemetryService.sendEvent(event)
    }

    func upgradeAttempt(storeKitProductId: String?) async {
        let dimensions = makeDimensions(storeKitProductId: storeKitProductId)
        let event = makeEvent(name: .upgradeAttempt, dimensions: dimensions)
        await dependencies.telemetryService.sendEvent(event)
    }

    func upgradeSuccess(storeKitProductId: String?) async {
        let dimensions = makeDimensions(storeKitProductId: storeKitProductId)
        let event = makeEvent(name: .upgradeSuccess, dimensions: dimensions)
        await dependencies.telemetryService.sendEvent(event)
    }

    func upgradeFailed(storeKitProductId: String?) async {
        let dimensions = makeDimensions(storeKitProductId: storeKitProductId)
        let event = makeEvent(name: .upgradeFailed, dimensions: dimensions)
        await dependencies.telemetryService.sendEvent(event)
    }

    func upgradeCancelled(storeKitProductId: String?) async {
        let dimensions = makeDimensions(storeKitProductId: storeKitProductId)
        let event = makeEvent(name: .upgradeCancelled, dimensions: dimensions)
        await dependencies.telemetryService.sendEvent(event)
    }

    private func makeDimensions(storeKitProductId: String? = nil) -> Dimensions {
        if !ProcessInfo.isRunningUnitTests {
            assert(
                planBeforeUpgrade != nil,
                "current plan name must be stored to accurately report it after the upgrade"
            )
        }

        var dimensions = Dimensions(
            entryPoint: entryPoint?.dimensionName,
            planBeforeUpgrade: planBeforeUpgrade ?? "unknown",
            daysSinceAccountCreation: accountAgeBracket(),
            upsellModalVersion: "\(upsellPageVariant?.dimensionName ?? "unknown").1"
        )

        if let storeKitProductId, let (selectedPlan, selectedCycle) = parsePlanNameAndCycle(from: storeKitProductId) {
            dimensions.selectedPlan = selectedPlan
            dimensions.selectedCycle = selectedCycle
        }

        return dimensions
    }

    private func parsePlanNameAndCycle(
        from storeKitProductId: String?
    ) -> (name: String, cycle: String)? {
        guard
            let storeKitProductId = storeKitProductId,
            let regex = try? NSRegularExpression(
                pattern: "^ios[^_]*_([^_]*)_?(.*)_(\\d+)_(\\w+)_(?:non_|auto_)renewing(?:_v\\d+)?$"
            ),
            let result = regex.firstMatch(
                in: storeKitProductId,
                range: NSRange(location: 0, length: storeKitProductId.count)
            ),
            result.numberOfRanges == 5
        else {
            return nil
        }

        let captureGroupAtIndex: (Int) -> String = {
            let range = result.range(at: $0)
            return NSString(string: storeKitProductId).substring(with: range)
        }

        return (captureGroupAtIndex(1), captureGroupAtIndex(3))
    }

    private func accountAgeBracket() -> String {
        let accountCreationDate = Date(timeIntervalSince1970: TimeInterval(dependencies.user.userInfo.createTime))
        let now = Date()
        let accountAgeInDays = Calendar.autoupdatingCurrent.numberOfDays(between: accountCreationDate, and: now)
        return accountAgeBracket(for: accountAgeInDays)
    }

    private func makeEvent(name: EventName, dimensions: Dimensions) -> TelemetryEvent {
        .init(
            measurementGroup: measurementGroup,
            name: name.rawValue,
            values: [:],
            dimensions: dimensions.asDictionary,
            frequency: .always
        )
    }
}

private extension UpsellTelemetryReporter {
    enum EventName: String {
        case upsellButtonTapped = "upsell_button_tapped"
        case upgradeAttempt = "upgrade_attempt"
        case upgradeSuccess = "upgrade_success"
        case upgradeFailed = "upgrade_error"
        case upgradeCancelled = "upgrade_cancelled_by_user"
    }

    struct Dimensions {
        let entryPoint: String?
        let planBeforeUpgrade: String
        let daysSinceAccountCreation: String
        let upsellModalVersion: String
        var selectedPlan: String?
        var selectedCycle: String?

        var asDictionary: [String: String] {
            [
                "upsell_entry_point": entryPoint,
                "plan_before_upgrade": planBeforeUpgrade,
                "days_since_account_creation": daysSinceAccountCreation,
                "upsell_modal_version": upsellModalVersion,
                "selected_plan": selectedPlan,
                "selected_cycle": selectedCycle
            ].compactMapValues { $0 }
        }
    }

    var measurementGroup: String {
        "mail.any.upsell"
    }

    func accountAgeBracket(for accountAgeInDays: Int) -> String {
        let validBrackets: [ClosedRange<Int>] = [
            1...3,
            4...10,
            11...30,
            31...60
        ]

        if accountAgeInDays == 0 {
            return "0"
        } else if let matchingBracket = validBrackets.first(where: { $0.contains(accountAgeInDays) }) {
            return String(format: "%02d-%02d", matchingBracket.lowerBound, matchingBracket.upperBound)
        } else if let maximumUpperBound = validBrackets.map(\.upperBound).max(), accountAgeInDays > maximumUpperBound {
            return ">\(maximumUpperBound)"
        } else {
            return "n/a"
        }
    }
}

private extension Calendar {
    func numberOfDays(between startDate: Date, and endDate: Date) -> Int {
        let fromDate = startOfDay(for: startDate)
        let toDate = startOfDay(for: endDate)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
        return numberOfDays.day ?? 0
    }
}

private extension UpsellPageEntryPoint {
    var dimensionName: String {
        switch self {
        case .autoDelete:
            return "auto_delete_messages"
        case .contactGroups:
            return "contact_groups"
        case .folders:
            return "folders_creation"
        case .header:
            return "mailbox_top_bar"
        case .labels:
            return "labels_creation"
        case .mobileSignature:
            return "mobile_signature_edit"
        case .postOnboarding:
            return "post_onboarding"
        case .scheduleSend:
            return "schedule_send"
        case .snooze:
            return "snooze"
        }
    }
}

private extension UpsellPageModel.Variant {
    var dimensionName: String {
        switch self {
        case .plain:
            return "A"
        case .comparison:
            return "B"
        case .carousel:
            return "C"
        }
    }
}
