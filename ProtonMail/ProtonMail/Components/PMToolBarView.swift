// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import UIKit
import ProtonCore_UIFoundations

class PMToolBarView: UIView {

    let btnStackView = UIStackView(arrangedSubviews: [])
    let unreadButton = SubviewFactory.unreadButton
    let trashButton = SubviewFactory.trashButton
    let moveToButton = SubviewFactory.moveToButton
    let labelAsButton = SubviewFactory.labelAsButton
    let moreButton = SubviewFactory.moreButton
    let deleteButton = SubviewFactory.deleteButton

    lazy var unreadButtonView = SubviewFactory.makeButtonView(btn: unreadButton)
    lazy var trashButtonView = SubviewFactory.makeButtonView(btn: trashButton)
    lazy var moveToButtonView = SubviewFactory.makeButtonView(btn: moveToButton)
    lazy var labelAsButtonView = SubviewFactory.makeButtonView(btn: labelAsButton)
    lazy var moreButtonView = SubviewFactory.makeButtonView(btn: moreButton)
    lazy var deleteButtonView = SubviewFactory.makeButtonView(btn: deleteButton)
    let separatorView = SubviewFactory.separatorView

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        setUpViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func setUpUnreadAction(target: UIViewController, action: Selector) {
        unreadButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func setUpMoveToAction(target: UIViewController, action: Selector) {
        moveToButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func setUpLabelAsAction(target: UIViewController, action: Selector) {
        labelAsButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func setUpTrashAction(target: UIViewController, action: Selector) {
        trashButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func setUpMoreAction(target: UIViewController, action: Selector) {
        moreButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func setUpDeleteAction(target: UIViewController, action: Selector) {
        deleteButton.addTarget(target, action: action, for: .touchUpInside)
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
            btnStackView.heightAnchor.constraint(equalToConstant: 56.0)
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
        btnStackView.distribution = .fillEqually
        btnStackView.axis = .horizontal
        btnStackView.addArrangedSubview(unreadButtonView)
        btnStackView.addArrangedSubview(deleteButtonView)
        btnStackView.addArrangedSubview(trashButtonView)
        btnStackView.addArrangedSubview(moveToButtonView)
        btnStackView.addArrangedSubview(labelAsButtonView)
        btnStackView.addArrangedSubview(moreButtonView)
        backgroundColor = UIColorManager.BackgroundNorm
    }

    required init?(coder: NSCoder) {
        nil
    }

    private enum SubviewFactory {
        static var unreadButton: UIButton {
            let button = UIButton(type: .system)
            button.imageView?.contentMode = .scaleAspectFit
            button.setImage(Asset.actionBarReadUnread.image, for: .normal)
            button.tintColor = UIColorManager.IconNorm
            return button
        }

        static var deleteButton: UIButton {
            let button = UIButton(type: .system)
            button.imageView?.contentMode = .scaleAspectFit
            button.setImage(Asset.actionBarDelete.image, for: .normal)
            button.tintColor = UIColorManager.IconNorm
            return button
        }

        static var trashButton: UIButton {
            let button = UIButton(type: .system)
            button.imageView?.contentMode = .scaleAspectFit
            button.setImage(Asset.actionBarTrash.image, for: .normal)
            button.tintColor = UIColorManager.IconNorm
            return button
        }

        static var moveToButton: UIButton {
            let button = UIButton(type: .system)
            button.imageView?.contentMode = .scaleAspectFit
            button.setImage(Asset.actionBarMoveTo.image, for: .normal)
            button.tintColor = UIColorManager.IconNorm
            return button
        }

        static var labelAsButton: UIButton {
            let button = UIButton(type: .system)
            button.imageView?.contentMode = .scaleAspectFit
            button.setImage(Asset.actionBarLabel.image, for: .normal)
            button.tintColor = UIColorManager.IconNorm
            return button
        }

        static var moreButton: UIButton {
            let button = UIButton(type: .system)
            button.imageView?.contentMode = .scaleAspectFit
            button.setImage(Asset.actionBarMore.image, for: .normal)
            button.tintColor = UIColorManager.IconNorm
            return button
        }

        static var separatorView: UIView {
            let view = UIView()
            view.backgroundColor = UIColorManager.Shade20
            return view
        }

        static func makeButtonView(btn: UIButton) -> UIView {
            let view = UIView()
            view.backgroundColor = .clear
            view.addSubview(btn)
            [
                btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                btn.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                btn.topAnchor.constraint(equalTo: view.topAnchor),
                btn.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                btn.heightAnchor.constraint(equalToConstant: 40.0)
            ].activate()
            return view
        }
    }
}
