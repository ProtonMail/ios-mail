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

final class ToolbarSettingView: UIView {
    let containerView = UIView()
    let segmentControl = SubviewsFactory.segmentControl
    let infoBubbleView = SubviewsFactory.infoBubbleView

    init() {
        super.init(frame: .zero)
        addSubviews()
        setupLayout()
        backgroundColor = ColorProvider.BackgroundNorm
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        addSubview(containerView)
        addSubview(segmentControl)
        addSubview(infoBubbleView)
    }

    private func setupLayout() {
        [
            segmentControl.heightAnchor.constraint(equalToConstant: 36.0),
            segmentControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            segmentControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            segmentControl.topAnchor.constraint(equalTo: topAnchor, constant: 16)
        ].activate()

        [
            infoBubbleView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 21),
            infoBubbleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            infoBubbleView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ].activate()

        [
            containerView.topAnchor.constraint(equalTo: infoBubbleView.bottomAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }
}

private enum SubviewsFactory {
    static var segmentControl: UISegmentedControl {
        let control = UISegmentedControl(items: [LocalString._toolbar_setting_segment_title_message,
                                                 LocalString._menu_inbox_title])
        return control
    }

    static var infoBubbleView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundSecondary
        view.roundCorner(8.0)
        let infoIcon = UIImageView(image: IconProvider.infoCircle)
        infoIcon.tintColor = ColorProvider.IconNorm
        let infoLabel = UILabel()
        infoLabel.numberOfLines = 0

        view.addSubview(infoIcon)
        view.addSubview(infoLabel)

        [
            infoIcon.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            infoIcon.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 13.5)
        ].activate()

        [
            infoLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            infoLabel.leadingAnchor.constraint(equalTo: infoIcon.trailingAnchor, constant: 9),
            infoLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ].activate()

        return view
    }

}
