//
//  PlanSectionHeaderView.swift
//  ProtonCore-PaymentsUI - Created on 09.11.21.
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

protocol CycleSelectorDelegate: AnyObject {
    func didSelectCycle(cycle: Int?)
}

class PlanSectionHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cycleSelectorButton: UIButton!

    weak var cycleSelectorDelegate: CycleSelectorDelegate?
    private var cycles = [(description: String, cycle: Int)]()

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = ColorProvider.BackgroundNorm
        titleLabel.textColor = ColorProvider.TextNorm
        titleLabel.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
        titleLabel.adjustsFontSizeToFitWidth = false

        cycleSelectorButton.setImage(IconProvider.chevronDown, for: .normal)
        cycleSelectorButton.tintColor = ColorProvider.InteractionNorm
        cycleSelectorButton.imageView?.contentMode = .scaleAspectFit
        cycleSelectorButton.imageEdgeInsets = UIEdgeInsets(top: 5, left: 3, bottom: 3, right: 3)
        cycleSelectorButton.semanticContentAttribute = .forceRightToLeft
        cycleSelectorButton.showsMenuAsPrimaryAction = true
        cycleSelectorButton.roundCorner(8)
        cycleSelectorButton.setTitleColor(ColorProvider.InteractionNorm, for: .normal)
        cycleSelectorButton.setTitleColor(ColorProvider.InteractionNormPressed, for: .highlighted)
    }

    func configureCycleSelector(cycles: Set<Int>, selectedCycle: Int?) {
        guard cycles.count > 1 else {
            cycleSelectorButton.isHidden = true
            setNeedsLayout()
            return
        }

        cycleSelectorButton.isHidden = false

        self.cycles = cycles.sorted().map {
            switch $0 {
            case 1:
                return (PUITranslations.plan_cycle_one_month.l10n, $0)
            case 12:
                return (PUITranslations.plan_cycle_one_year.l10n, $0)
            case 24:
                return (PUITranslations.plan_cycle_two_years.l10n, $0)
            default:
                return (String(format: PUITranslations.plan_cycle_x_months.l10n, $0), $0)
            }
        }

        let cycleSelectionClosure = { [weak self] (action: UIAction) in
            guard let self else { return }
            self.cycleSelectorDelegate?.didSelectCycle(
                cycle: self.cycles.first(where: { (description, _) in
                    action.title == description
                })?.cycle
            )
        }

        cycleSelectorButton.setTitle(self.cycles.first(where: { (_, cycle) in
            cycle == selectedCycle
        })?.description ?? PUITranslations.plan_cycle_one_month.l10n, for: .normal)

        cycleSelectorButton.sizeToFit()
        cycleSelectorButton.menu = UIMenu(
            children: self.cycles.map {
                UIAction(title: $0.description, handler: cycleSelectionClosure)
            }
        )
    }
}

#endif
