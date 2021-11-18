//
//  SummaryViewModel.swift
//  ProtonCore-Login - Created on 11/03/2021.
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation
import ProtonCore_CoreTranslation
import ProtonCore_UIFoundations

class SummaryViewModel {
    
    private let planName: String?
    private let screenVariant: SummaryScreenVariant
    
    // MARK: Public interface
    
    init(planName: String?, screenVariant: SummaryScreenVariant) {
        self.planName = planName
        self.screenVariant = screenVariant
    }
    
    var descriptionText: NSAttributedString {
        let attrFont = UIFont.systemFont(ofSize: 17, weight: .bold)
        if let planName = planName {
            return String(format: CoreString._su_summary_paid_description, planName).getAttributedString(replacement: planName, attrFont: attrFont)
        } else {
            return CoreString._su_summary_free_description.getAttributedString(replacement: CoreString._su_summary_free_description_replacement, attrFont: attrFont)
        }
    }
    
    var summaryImage: UIImage? {
        if case .custom(let data) = screenVariant{
            return data.image
        }
        return nil
    }

    var startButtonText: String? {
        switch screenVariant {
        case .mail(let text), .vpn(let text), .drive(let text), .calendar(let text):
            return text
        case .custom(let data):
            return data.startButtonText
        }
    }
    
    // MARK: Private interface

    private func getImage(name: String) -> UIImage? {
        return UIImage(named: name, in: LoginAndSignup.bundle, compatibleWith: nil)
    }
}
