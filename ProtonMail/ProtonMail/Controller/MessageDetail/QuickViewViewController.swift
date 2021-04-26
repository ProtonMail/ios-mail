//
//  QuickViewViewController.swift
//  ProtonMail - Created on 9/21/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import PMUIFoundations
import QuickLook
import UIKit

class QuickViewViewController: QLPreviewController {
    private var isPresented = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let views = self.children
        if !views.isEmpty {
            if let nav = views[0] as? UINavigationController {
                configureNavigationBar(nav)
                setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        isPresented = false
        super.viewWillDisappear(animated)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    private func configureNavigationBar(_ navigationController: UINavigationController) {
        navigationController.navigationBar.barTintColor = UIColorManager.BackgroundNorm
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.tintColor = UIColorManager.TextNorm

        navigationController.navigationBar.titleTextAttributes = FontManager.DefaultSmallStrong
    }
}
