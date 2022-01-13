//
//  PMHeaderView.swift
//  ProtonCore-UIFoundations - Created on 03.17.21.
//
//  Copyright (c) 2020 Proton Technologies AG
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
import ProtonCore_Foundations

public final class PMHeaderView: UIView, AccessibleView {

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var titleLabelLeft: NSLayoutConstraint!
    @IBOutlet private var titleLabelBottom: NSLayoutConstraint!
    @IBOutlet private var contentView: UIView!
    private let title: String
    private let fontSize: CGFloat
    private let titleColor: UIColor
    private let titleLeft: CGFloat
    private let titleBottom: CGFloat
    private let background: UIColor

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(title: String,
                fontSize: CGFloat = 15,
                titleColor: UIColor = ColorProvider.TextWeak,
                titleLeft: CGFloat = 16,
                titleBottom: CGFloat = 8,
                background: UIColor = ColorProvider.BackgroundSecondary) {
        self.title = title
        self.fontSize = fontSize
        self.titleColor = titleColor
        self.titleLeft = titleLeft
        self.titleBottom = titleBottom
        self.background = background
        super.init(frame: .zero)
        self.nibSetup()
    }
}

extension PMHeaderView {
    private func nibSetup() {
        self.contentView = loadViewFromNib()
        self.contentView.frame = bounds
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.translatesAutoresizingMaskIntoConstraints = true

        addSubview(self.contentView)
        self.setup()
        generateAccessibilityIdentifiers()
    }

    private func loadViewFromNib() -> UIView {
        let bundle = PMUIFoundations.bundle
        let name = String(describing: PMHeaderView.self)
        let nib = UINib(nibName: name, bundle: bundle)
        let nibView = nib.instantiate(withOwner: self, options: nil).first as! UIView

        return nibView
    }

    private func setup() {
        self.contentView.backgroundColor = self.background
        self.titleLabel.text = self.title
        self.titleLabel.textColor = self.titleColor
        self.titleLabel.font = .systemFont(ofSize: self.fontSize)
        self.titleLabelLeft.constant = self.titleLeft
        self.titleLabelBottom.constant = self.titleBottom
    }
}
