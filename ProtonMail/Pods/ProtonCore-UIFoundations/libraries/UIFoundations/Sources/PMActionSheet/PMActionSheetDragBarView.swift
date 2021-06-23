//
//  PMActionSheetDragBarView.swift
//  ProtonMail - Created on 21.01.21.
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import UIKit

final class PMActionSheetDragBarView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

}

extension PMActionSheetDragBarView {
    private func setup() {
        self.setupBar()
        self.backgroundColor = UIColorManager.BackgroundNorm
    }

    private func setupBar() {
        let bar = UIView(frame: .zero)
        bar.backgroundColor = UIColorManager.InteractionWeakPressed
        bar.roundCorner(2)
        self.addSubview(bar)
        bar.setSizeContraint(height: 4, width: 40)
        bar.centerXInSuperview()
        bar.centerYInSuperview()
    }
}
