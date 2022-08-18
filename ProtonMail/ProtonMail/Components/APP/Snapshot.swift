//
//  Snapshot.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_UIFoundations
import UIKit

class Snapshot {
    private enum Tag {
        static let snapshot = 101
    }

    private enum NibName {
        static let Name = "LaunchScreen"
    }

    private lazy var view: UIView = self.getFancyView() ?? self.getDefaultView()

    func show(at window: UIView) {
        window.addSubview(self.view)
        [
            view.topAnchor.constraint(equalTo: window.topAnchor),
            view.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ].activate()
    }

    func remove() {
        view.removeFromSuperview()
    }

    private func getFancyView() -> UIView? {
        guard let view = Bundle.main
                .loadNibNamed(NibName.Name, owner: nil, options: nil)?.first as? UIView else {
            return nil
        }
        view.backgroundColor = ColorProvider.BackgroundNorm
        view.tag = Tag.snapshot
        return view
    }

    private func getDefaultView() -> UIView {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = ColorProvider.BackgroundNorm
        view.tag = Tag.snapshot
        return view
    }
}
