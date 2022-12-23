// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import MBProgressHUD
import ProtonCore_UIFoundations
import UIKit

final class MessagePlaceholderVC: UIViewController {
    private lazy var customView = MessagePlaceholderView()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let actions: [MessageViewActionSheetAction] = [.markRead, .trash, .moveTo, .labelAs, .more]
        customView.toolBar.setUpActions(actions.map { PMToolBarView.ActionItem(type: $0) { } })

        let barItem = UIBarButtonItem(image: IconProvider.star, style: .plain, target: nil, action: nil)
        barItem.tintColor = ColorProvider.IconWeak
        navigationItem.rightBarButtonItem = barItem

        MBProgressHUD.showAdded(to: self.view, animated: true)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        customView.toolBarHeight.constant = view.safeGuide.bottom + 56.0
    }
}
