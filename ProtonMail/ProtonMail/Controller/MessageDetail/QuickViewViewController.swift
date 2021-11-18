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

import MBProgressHUD
import ProtonCore_UIFoundations
import QuickLook
import UIKit

class QuickViewViewController: QLPreviewController {
    private var isPresented = true
    private var loadingView: UIView?

    override var shouldAutorotate: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.dismissWhenAppGoesToBackground),
                                                   name: UIWindowScene.didEnterBackgroundNotification,
                                                   object: nil)
        } else {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.dismissWhenAppGoesToBackground),
                                                   name: UIApplication.didEnterBackgroundNotification,
                                                   object: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let views = self.children
        if !views.isEmpty {
            if let nav = views[0] as? UINavigationController {
                configureNavigationBar(nav)
                setNeedsStatusBarAppearanceUpdate()
            }
        }
        self.showLoadingViewIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isPresented = false
    }

    func removeLoadingView(needDelay: Bool) {
        if let view = self.loadingView {
            // Some file needs more time to process
            // To avoid the loading view disappear too early, add a delay
            let time: Double = needDelay ? 2: 0.8
            delay(time) { [weak self] in
                view.removeFromSuperview()
                MBProgressHUD.hide(for: view, animated: true)
                self?.loadingView = nil
            }
        }
    }

    @objc
    func dismissWhenAppGoesToBackground() {
        dismiss(animated: true, completion: nil)
    }

    private func configureNavigationBar(_ navigationController: UINavigationController) {
        navigationController.navigationBar.barTintColor = ColorProvider.BackgroundNorm
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.tintColor = ColorProvider.TextNorm

        navigationController.navigationBar.titleTextAttributes = FontManager.DefaultSmallStrong
    }

    private func showLoadingViewIfNeeded() {
        guard let numberOfItems = self.dataSource?.numberOfPreviewItems(in: self),
              numberOfItems == 0,
              let navController = self.children.first(where: { $0 is UINavigationController }) else { return }

        let view = UIView(frame: .zero)
        // Todo: Is it ok when dark mode enabled
        view.backgroundColor = .white
        self.view.insertSubview(view, belowSubview: navController.view)
        [
            view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 44),
            view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        ].activate()
        self.loadingView = view
        MBProgressHUD.showAdded(to: view, animated: true)
    }
}
