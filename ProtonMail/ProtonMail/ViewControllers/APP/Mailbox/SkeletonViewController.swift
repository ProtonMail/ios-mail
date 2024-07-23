//
//  SkeletonViewController.swift
//  Proton Mail - Created on 8/16/15.
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

import ProtonCoreServices
import SkeletonView
import ProtonCoreUIFoundations
import UIKit

class SkeletonViewController: ProtonMailTableViewController {
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(style: .plain)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        SkeletonAppearance.default.tintColor = ColorProvider.BackgroundSecondary
        SkeletonAppearance.default.gradient = SkeletonGradient(baseColor: ColorProvider.BackgroundSecondary)
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.tableView.isScrollEnabled = false
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.separatorColor = ColorProvider.InteractionWeak
        self.tableView.registerCell(MailBoxSkeletonLoadingCell.Constant.identifier)
        self.tableView.backgroundColor = ColorProvider.BackgroundNorm
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
            self.view.window?.windowScene?.title = LocalString._menu_inbox_title
        self.view.backgroundColor = ColorProvider.BackgroundNorm
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        10
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = MailBoxSkeletonLoadingCell.Constant.identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.showAnimatedGradientSkeleton()
        cell.contentView.backgroundColor = ColorProvider.BackgroundNorm
        cell.backgroundColor = ColorProvider.BackgroundNorm
        return cell
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
}
