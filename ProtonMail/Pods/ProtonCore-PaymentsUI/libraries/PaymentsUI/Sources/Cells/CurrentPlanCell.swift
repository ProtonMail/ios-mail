//
//  CurrentPlanCell.swift
//  ProtonCorePaymentsUI - Created on 01/06/2021.
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

import UIKit
import ProtonCoreUIFoundations
import ProtonCoreFoundations

final class CurrentPlanCell: UITableViewCell, AccessibleCell {

    static let reuseIdentifier = "CurrentPlanCell"
    static let nib = UINib(nibName: "CurrentPlanCell", bundle: PaymentsUI.bundle)

    // MARK: - Outlets
    
    @IBOutlet weak var mainView: UIView! {
        didSet {
            mainView.layer.cornerRadius = 12.0
            mainView.layer.borderWidth = 1.0
            mainView.layer.borderColor = ColorProvider.SeparatorNorm
        }
    }
    @IBOutlet weak var planNameLabel: UILabel! {
        didSet {
            planNameLabel.textColor = ColorProvider.TextNorm
        }
    }
    @IBOutlet weak var planDescriptionLabel: UILabel! {
        didSet {
            planDescriptionLabel.textColor = ColorProvider.TextWeak
            planDescriptionLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        }
    }
    @IBOutlet weak var priceLabel: UILabel! {
        didSet {
            priceLabel.textColor = ColorProvider.TextNorm
        }
    }
    @IBOutlet weak var priceDescriptionLabel: UILabel! {
        didSet {
            priceDescriptionLabel.textColor = ColorProvider.TextWeak
        }
    }
    @IBOutlet weak var progressBarSpacerView: UIView!
    @IBOutlet weak var progressBarView: StorageProgressView!
    @IBOutlet weak var planDetailsStackView: UIStackView!
    @IBOutlet weak var timeSeparator1View: UIView!
    @IBOutlet weak var separatorLineView: UIView! {
        didSet {
            separatorLineView.backgroundColor = ColorProvider.Shade20
        }
    }
    @IBOutlet weak var timeSeparator2View: UIView!
    @IBOutlet weak var planTimeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        planNameLabel.font = .adjustedFont(forTextStyle: .headline, weight: .semibold)
        planDescriptionLabel.font = .adjustedFont(forTextStyle: .footnote)
        priceLabel.font = .adjustedFont(forTextStyle: .body, weight: .bold)
        priceDescriptionLabel.font = .adjustedFont(forTextStyle: .footnote)
    }
    // MARK: - Properties
    
    func configurePlan(plan: PlanPresentation) {
        planDetailsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard case PlanPresentationType.current(let planDetails) = plan.planPresentationType else { return }
        switch planDetails {
        case .details(let planDetails):
            configureCurrentPlan(plan: plan, currentPlanDetails: planDetails)
        case .unavailable:
            configureUnavailablePlan()
        }
    }
    
    private func configureCurrentPlan(plan: PlanPresentation, currentPlanDetails: CurrentPlanDetails) {
        generateCellAccessibilityIdentifiers(currentPlanDetails.name)
        
        planNameLabel.text = currentPlanDetails.name
        planDescriptionLabel.text = PUITranslations.current_plan_title.l10n
        
        if let price = currentPlanDetails.price {
            priceLabel.isHidden = false
            priceDescriptionLabel.isHidden = false
            priceLabel.text = price
            priceDescriptionLabel.text = currentPlanDetails.cycle
        } else {
            priceLabel.isHidden = true
            priceDescriptionLabel.isHidden = true
        }
        if let usedSpaceDescription = currentPlanDetails.usedSpaceDescription {
            progressBarView.configure(usedSpaceDescription: usedSpaceDescription, usedSpace: currentPlanDetails.usedSpace, maxSpace: currentPlanDetails.maxSpace)
        } else {
            // No progress view, hide it
            progressBarSpacerView.isHidden = true
            progressBarView.isHidden = true
        }
        currentPlanDetails.details.forEach {
            let detailView = PlanDetailView()
            detailView.configure(icon: $0.0.icon, text: $0.1)
            planDetailsStackView.addArrangedSubview(detailView)
        }
        if let endDate = currentPlanDetails.endDate {
            enableTimeView(enabled: true)
            planTimeLabel.attributedText = endDate
            planTimeLabel.font = .adjustedFont(forTextStyle: .footnote)
        } else {
            enableTimeView(enabled: false)
        }
    }
    
    private func configureUnavailablePlan() {
        planNameLabel.text = ""
        priceLabel.text = ""
        priceDescriptionLabel.text = ""
        planDescriptionLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
        planDescriptionLabel.text = PUITranslations.plan_details_plan_details_unavailable_contact_administrator.l10n
        planDescriptionLabel.textColor = ColorProvider.TextNorm
        enableProgressView(enabled: false)
        enableTimeView(enabled: false)
    }
    
    // MARK: Private interface
    
    private func enableTimeView(enabled: Bool) {
        timeSeparator1View.isHidden = !enabled
        separatorLineView.isHidden = !enabled
        timeSeparator2View.isHidden = !enabled
        planTimeLabel.isHidden = !enabled
    }
    
    private func enableProgressView(enabled: Bool) {
        progressBarSpacerView.isHidden = !enabled
        progressBarView.isHidden = !enabled
    }
}

// TODO: write snapshot tests: CP-6481
// MARK: - Dynamic plans

extension CurrentPlanCell {
    func configurePlan(currentPlan: CurrentPlanPresentation) {
        planDetailsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        generateCellAccessibilityIdentifiers(currentPlan.details.title)
        
        planNameLabel.text = currentPlan.details.title
        planDescriptionLabel.text = PUITranslations.current_plan_title.l10n
        
        priceLabel.isHidden = currentPlan.details.hidePriceDetails
        priceDescriptionLabel.isHidden = currentPlan.details.hidePriceDetails
        priceLabel.text = currentPlan.details.price
        priceDescriptionLabel.text = currentPlan.details.cycleDescription
        
        progressBarSpacerView.isHidden = true
        progressBarView.isHidden = true
        
        for entitlement in currentPlan.details.entitlements {
            switch entitlement {
            case .progress(let progressEntitlement):
                progressBarSpacerView.isHidden = false
                progressBarView.isHidden = false
                progressBarView.configure(
                    usedSpaceDescription: progressEntitlement.text,
                    usedSpace: Int64(progressEntitlement.current),
                    maxSpace: Int64(progressEntitlement.max)
                )
            case .description(let descriptionEntitlement):
                let detailView = PlanDetailView()
                detailView.configure(iconUrl: descriptionEntitlement.iconUrl, text: descriptionEntitlement.text)
                planDetailsStackView.addArrangedSubview(detailView)
            }
        }
        
        if let endDate = currentPlan.details.endDate {
            enableTimeView(enabled: true)
            planTimeLabel.attributedText = endDate
            planTimeLabel.font = .adjustedFont(forTextStyle: .footnote)
        } else {
            enableTimeView(enabled: false)
        }
    }
}

#endif
