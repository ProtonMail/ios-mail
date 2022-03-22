//
//  PlanDetailView.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
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

import UIKit
import ProtonCore_UIFoundations

final class PlanDetailView: UIView {

    static let reuseIdentifier = "PlanDetailView"
    static let nib = UINib(nibName: "PlanDetailView", bundle: PaymentsUI.bundle)

    // MARK: - Outlets

    @IBOutlet var mainView: UIView!
    @IBOutlet weak var iconImageView: UIImageView! {
        didSet {
            iconImageView?.tintColor = ColorProvider.InteractionNorm
        }
    }
    @IBOutlet weak var detailLabel: UILabel! {
        didSet {
            detailLabel.textColor = ColorProvider.TextNorm
        }
    }

    // MARK: - Properties
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        load()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        load()
    }

    private func load() {
        PaymentsUI.bundle.loadNibNamed(PlanDetailView.reuseIdentifier, owner: self, options: nil)
        addSubview(mainView)
        mainView.frame = bounds
        mainView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: mainView.topAnchor),
            bottomAnchor.constraint(equalTo: mainView.bottomAnchor),
            leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
            trailingAnchor.constraint(equalTo: mainView.trailingAnchor)
        ])
        backgroundColor = .clear
        mainView.backgroundColor = .clear
        detailLabel.backgroundColor = .clear
    }
    
    func configure(icon: UIImage? = nil, text: String) {
        iconImageView.image = icon ?? IconProvider.checkmark
        detailLabel.text = text
    }
    
}
