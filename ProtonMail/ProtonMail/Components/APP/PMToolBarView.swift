// Copyright (c) 2021 Proton AG
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

class PMToolBarView: UIView {

    struct ActionItem {
        let type: MessageViewActionSheetAction
        let handler: () -> Void
    }

    let btnStackView = UIStackView(arrangedSubviews: [])
    let separatorView = SubviewFactory.separatorView

    private var actionHandlers: [() -> Void] = []
    private(set) var types: [MessageViewActionSheetAction] = []

    init() {
        super.init(frame: .zero)

        initialize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        initialize()
    }

    private func initialize() {
        addSubviews()
        setUpLayout()
        setUpViews()
        setUpGesture()
    }

    func setUpActions(_ actions: [ActionItem]) {
        assert(actions.count <= 6, "Should not pass more than 6 actions")

        // Maximum amount of actions is 6.
        let actions = actions.prefix(6)

        actionHandlers = actions.map(\.handler)
        types = actions.map(\.type)

        btnStackView.clearAllViews()

        btnStackView.addArrangedSubview(SubviewFactory.makeEdgeSpacer())

        var buttons: [UIButton] = []
        for (index, action) in actions.enumerated() {
            let button = UIButton(type: .system)
            button.imageView?.contentMode = .scaleAspectFit
            button.setImage(action.type.icon, for: .normal)
            button.tintColor = ColorProvider.IconNorm
            button.accessibilityIdentifier = action.type.accessibilityIdentifier
            button.tag = index
            button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
            buttons.append(button)
            btnStackView.addArrangedSubview(button)
            [
                button.widthAnchor.constraint(equalToConstant: 48.0),
                button.heightAnchor.constraint(equalToConstant: 40.0)
            ].activate()
        }
        btnStackView.addArrangedSubview(SubviewFactory.makeEdgeSpacer())
        accessibilityElements = buttons
    }

    private func addSubviews() {
        addSubview(btnStackView)
        addSubview(separatorView)
    }

    private func setUpLayout() {
        [
            btnStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            btnStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            btnStackView.topAnchor.constraint(equalTo: topAnchor),
            btnStackView.bottomAnchor.constraint(equalTo: bottomAnchor).setPriority(as: .defaultLow),
            btnStackView.heightAnchor.constraint(equalToConstant: 56),
        ].activate()

        [
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1)
        ].activate()
    }

    private func setUpViews() {
        btnStackView.alignment = .center
        btnStackView.distribution = .equalSpacing
        btnStackView.axis = .horizontal
        backgroundColor = ColorProvider.BackgroundNorm
    }

    private func setUpGesture() {
        // Add gesture to avoid the swipe gesture being triggered while tapping the action on the toolbar.
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.doNothing))
        addGestureRecognizer(gesture)
    }

    @objc
    private func actionButtonTapped(sender: UIButton) {
        self.actionHandlers[sender.tag]()
    }

    @objc
    private func doNothing() {}

    private enum SubviewFactory {
        static var separatorView: UIView {
            let view = UIView()
            view.backgroundColor = ColorProvider.Shade20
            return view
        }

        static func makeEdgeSpacer() -> UIView {
            // the point of the 0-width spacer is to piggyback on `equalSpacing` distribution
            // to generate horizontal margins that are equal to space between the items
            let spacer = UIView()
            spacer.widthAnchor.constraint(equalToConstant: 0).isActive = true
            return spacer
        }
    }
}
