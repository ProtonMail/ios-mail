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

import UIKit
import ProtonCore_UIFoundations

final class MessagePlaceholderView: UIView {
    let toolBar = SubviewsFactory.toolBar
    private(set) var toolBarHeight: NSLayoutConstraint = .init()

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundSecondary
        addSubviews()
        setUpLayout()
        accessibilityElements = [toolBar]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        self.addSubview(toolBar)
    }

    private func setUpLayout() {
        // 30 is placeholder number, will be updated to correct value later
        toolBarHeight = toolBar.heightAnchor.constraint(equalToConstant: 30)
        [
            toolBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            toolBarHeight
        ].activate()
    }
}

private enum SubviewsFactory {

    static var tableView: UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = ColorProvider.BackgroundSecondary
        return tableView
    }

    static var separator: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.Shade20
        return view
    }

    static var toolBar: PMToolBarView {
        let toolbar = PMToolBarView()
        return toolbar
    }
}
