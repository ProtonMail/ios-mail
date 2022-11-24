// Copyright (c) 2022 Proton AG
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

import ProtonCore_UIFoundations
import UIKit

final class ToolbarCustomizeView: UIView {

    let tableView = SubviewsFactory.tableView
    let infoContainerView = UIView()
    lazy var infoBubbleView = SubviewsFactory.infoBubbleView
    let footerView = UIView()
    let resetButton = SubviewsFactory.resetButton

    private var infoViewCloseClosure: (() -> Void)?

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        addSubviews()
        setUpLayout()
        setupTableFooterView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addInfoBubbleView(close: @escaping () -> Void) {
        infoContainerView.addSubview(infoBubbleView)

        [
            infoBubbleView.topAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: 8),
            infoBubbleView.bottomAnchor.constraint(equalTo: infoContainerView.bottomAnchor, constant: -8),
            infoBubbleView.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            infoBubbleView.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16)
        ].activate()

        let closeButton = infoBubbleView.subviews.compactMap({ $0 as? UIButton }).first
        closeButton?.addTarget(self,
                               action: #selector(dismissInfoBubbleView),
                               for: .touchUpInside)
        infoViewCloseClosure = close
    }

    private func addSubviews() {
        addSubview(infoContainerView)
        addSubview(tableView)
    }

    private func setUpLayout() {
        [
            infoContainerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            infoContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            infoContainerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ].activate()

        [
            tableView.topAnchor.constraint(equalTo: infoContainerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }

    private func setupTableFooterView() {
        footerView.backgroundColor = ColorProvider.BackgroundSecondary
        footerView.addSubview(resetButton)
        [
            resetButton.heightAnchor.constraint(equalToConstant: 48),
            resetButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            resetButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            resetButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: 0)
        ].activate()
        footerView.frame.size.height = 68
        tableView.tableFooterView = footerView
    }

    @objc
    func dismissInfoBubbleView() {
        infoContainerView.subviews.forEach({ $0.removeFromSuperview() })
        infoContainerView.heightAnchor.constraint(equalToConstant: 0).isActive = true
        infoViewCloseClosure?()
    }
}

private enum SubviewsFactory {
    static var tableView: UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = ColorProvider.BackgroundNorm
        return tableView
    }

    static var infoBubbleViewCloseButton: UIButton {
        let button = UIButton(image: IconProvider.cross)
        button.tintColor = ColorProvider.IconNorm
        button.imageEdgeInsets = .init(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }

    static var infoBubbleView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundSecondary
        view.roundCorner(8.0)
        let button = Self.infoBubbleViewCloseButton
        let infoText = LocalString._toolbar_customize_info_title
        var attribute = FontManager.CaptionWeak
        attribute[.font] = UIFont.adjustedFont(forTextStyle: .footnote)
        let infoLabel = UILabel(attributedString: infoText.apply(style: attribute))
        infoLabel.numberOfLines = 0

        view.addSubview(button)
        view.addSubview(infoLabel)

        [
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            button.heightAnchor.constraint(equalToConstant: 24),
            button.widthAnchor.constraint(equalToConstant: 24),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ].activate()

        [
            infoLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            infoLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            infoLabel.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -4)
        ].activate()

        return view
    }

    static var resetButton: UIButton {
        let button = UIButton()
        var attribute = FontManager.Default
        attribute[.font] = UIFont.adjustedFont(forTextStyle: .body)
        attribute[.foregroundColor] = ColorProvider.BrandNorm.cgColor
        button.setAttributedTitle(
            LocalString._toolbar_customize_reset_button__title.apply(style: attribute),
            for: .normal
        )
        button.backgroundColor = ColorProvider.BackgroundNorm
        return button
    }
}
