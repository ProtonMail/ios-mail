//
//  PlanCell.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import UIKit
import ProtonCore_UIFoundations
import ProtonCore_Foundations
import ProtonCore_CoreTranslation

protocol PlanCellDelegate: AnyObject {
    func userPressedSelectPlanButton(plan: Plan, completionHandler: @escaping () -> Void)
}

final class PlanCell: UITableViewCell, AccessibleCell {

    static let reuseIdentifier = "PlanCell"
    static let nib = UINib(nibName: "PlanCell", bundle: PaymentsUI.bundle)
    
    weak var delegate: PlanCellDelegate?
    var plan: Plan?

    // MARK: - Outlets
    
    @IBOutlet weak var mainView: UIView! {
        didSet {
            mainView.layer.borderWidth = 1.0
            mainView.layer.cornerRadius = 6.0
            mainView.layer.borderColor = UIColorManager.Shade20.cgColor
        }
    }
    @IBOutlet weak var planNameLabel: UILabel! {
        didSet {
            planNameLabel.textColor = UIColorManager.TextNorm
        }
    }
    @IBOutlet weak var planPriceSeparator: UIView!
    @IBOutlet weak var planPriceLabel: UILabel! {
        didSet {
            planPriceLabel.textColor = UIColorManager.TextNorm
        }
    }
    @IBOutlet weak var planDetailsStackView: UIStackView!
    @IBOutlet weak var spacerView: UIView!
    @IBOutlet weak var selectPlanButton: ProtonButton! {
        didSet {
            selectPlanButton.setMode(mode: .solid)
        }
    }
    
    @IBOutlet weak var timeSeparator1View: UIView!
    @IBOutlet weak var separatorLineView: UIView! {
        didSet {
            separatorLineView.backgroundColor = UIColorManager.Shade20
        }
    }
    @IBOutlet weak var timeSeparator2View: UIView!
    @IBOutlet weak var planTimeLabel: UILabel! {
        didSet {
            planTimeLabel.textColor = UIColorManager.TextWeak
        }
    }
    
    // MARK: - Properties
    
    func configurePlan(plan: Plan, isSignup: Bool) {
        planDetailsStackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        self.plan = plan
        planNameLabel.text = plan.name
        
        switch plan.title {
        case .price(let price):
            if let price = price {
                let attributedText = NSMutableAttributedString(string: price, attributes: [.font: UIFont.systemFont(ofSize: 22), .foregroundColor: UIColorManager.TextNorm])
                attributedText.append(NSAttributedString(string: CoreString._pu_plan_details_price_time_period, attributes: [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColorManager.TextWeak]))
                planPriceLabel.attributedText = attributedText
            } else {
                planPriceSeparator.isHidden = true
                planPriceLabel.isHidden = true
            }
        case .current:
            planPriceLabel.textColor = UIColorManager.TextWeak
            planPriceLabel.font = .systemFont(ofSize: 17.0)
            planPriceLabel.text = CoreString._pu_current_plan_title
        }
        
        plan.details.forEach {
            let detailView = PlanDetailView()
            detailView.configure(text: $0)
            planDetailsStackView.addArrangedSubview(detailView)
        }
        
        spacerView.isHidden = !plan.isSelectable
        selectPlanButton.isHidden = !plan.isSelectable
        if let endDate = plan.endDate {
            enableTimeView(enabled: true)
            planTimeLabel.attributedText = endDate
        } else {
            enableTimeView(enabled: false)
        }
        if isSignup {
            selectPlanButton.setTitle(CoreString._pu_select_plan_button, for: .normal)
        } else {
            selectPlanButton.setTitle(CoreString._pu_upgrade_plan_button, for: .normal)
        }
        self.generateCellAccessibilityIdentifiers(plan.name)
    }
    
    private func enableTimeView(enabled: Bool) {
        timeSeparator1View.isHidden = !enabled
        separatorLineView.isHidden = !enabled
        timeSeparator2View.isHidden = !enabled
        planTimeLabel.isHidden = !enabled
    }
    
    // MARK: - Actions
    
    @IBAction func onSelectPlanButtonTap(_ sender: ProtonButton) {
        if let plan = plan {
            selectPlanButton.isSelected = true
            delegate?.userPressedSelectPlanButton(plan: plan) {
                DispatchQueue.main.async {
                    self.selectPlanButton.isSelected = false
                }
            }
        }
    }
    
}
