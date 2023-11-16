//
//  SummaryViewModel.swift
//  ProtonCore-Login - Created on 11/03/2021.
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

#if os(iOS)

import Foundation
import ProtonCoreDataModel
import ProtonCoreUIFoundations
import UIKit

class SummaryViewModel {

    private let planName: String?
    private let screenVariant: SummaryScreenVariant
    private let clientApp: ClientApp
    private let paymentsAvailability: PaymentsAvailability

    // MARK: Public interface

    init(planName: String?, paymentsAvailability: PaymentsAvailability,
         screenVariant: SummaryScreenVariant, clientApp: ClientApp) {
        self.planName = planName
        self.screenVariant = screenVariant
        self.clientApp = clientApp
        self.paymentsAvailability = paymentsAvailability
    }

    var descriptionText: NSAttributedString {
        let attrFont = UIFont.adjustedFont(forTextStyle: .body, weight: .bold)
        if case .notAvailable = paymentsAvailability {
            return NSAttributedString(string: LUITranslation.summary_no_plan_description.l10n)

        } else if let planName = planName {
            return String(format: LUITranslation.summary_paid_description.l10n, planName).getAttributedString(replacement: planName, attrFont: attrFont)

        } else {
            return LUITranslation.summary_free_description.l10n.getAttributedString(replacement: LUITranslation.summary_free_description_replacement.l10n, attrFont: attrFont)
        }
    }

    var summaryImage: UIImage? {
        switch screenVariant {
        case .noSummaryScreen:
            return nil
        case .screenVariant(let screenVariant):
            if case .custom(let data) = screenVariant {
                return data.image
            }
        }
        return nil
    }

    var startButtonText: String? {
        switch screenVariant {
        case .noSummaryScreen:
            return nil
        case .screenVariant(let screenVariant):
            switch screenVariant {
            case .mail(let text), .vpn(let text), .drive(let text), .calendar(let text), .pass(let text):
                return text
            case .custom(let data):
                return data.startButtonText
            }
        }
    }
}

#endif
