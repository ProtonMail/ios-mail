//
//  PlanDetailView.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

final class PlanDetailView: UIView {

    static let reuseIdentifier = "PlanDetailView"
    static let nib = UINib(nibName: "PlanDetailView", bundle: PaymentsUI.bundle)

    // MARK: - Outlets

    @IBOutlet var mainView: UIView!
    @IBOutlet weak var detailLabel: UILabel! {
        didSet {
            detailLabel.numberOfLines = 0
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
        mainView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func configure(text: String) {
        detailLabel.text = text
    }
    
}
