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

import ProtonCore_UIFoundations
import UIKit

final class PagesSpotlightView: UIView {
    private let flipIcon: Bool
    private let iconView = UIImageView(image: nil)
    private let mockToolBar = UIView(frame: .zero)
    private let mockTitleView = UIView(frame: .zero)
    var mockTitleViewHeight: NSLayoutConstraint?

    init(flipIcon: Bool) {
        self.flipIcon = flipIcon
        if flipIcon {
            self.iconView.image = IconProvider.swipeLeft.withHorizontallyFlippedOrientation()
        } else {
            self.iconView.image = IconProvider.swipeLeft
        }
        super.init(frame: .zero)
        self.backgroundColor = ColorProvider.BackgroundDeep
        setUpViews()
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        addSubview(iconView)
        addSubview(mockTitleView)
        addSubview(mockToolBar)

        iconView.tintColor = ColorProvider.IconWeak
        mockTitleView.backgroundColor = ColorProvider.BackgroundNorm
        mockToolBar.backgroundColor = ColorProvider.BackgroundNorm
    }

    private func setUpLayout() {
        [
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 203)
        ].activate()

        let mockToolBarHeight = 56 + UIDevice.safeGuide.bottom
        [
            mockToolBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            mockToolBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            mockToolBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            mockToolBar.heightAnchor.constraint(equalToConstant: mockToolBarHeight)
        ].activate()

        let toolbarSeparator = separator()
        mockToolBar.addSubview(toolbarSeparator)
        [
            toolbarSeparator.leadingAnchor.constraint(equalTo: mockToolBar.leadingAnchor),
            toolbarSeparator.trailingAnchor.constraint(equalTo: mockToolBar.trailingAnchor),
            toolbarSeparator.topAnchor.constraint(equalTo: mockToolBar.topAnchor),
            toolbarSeparator.heightAnchor.constraint(equalToConstant: 1)
        ].activate()

        let mockTitleViewHeight = mockTitleView.heightAnchor.constraint(equalToConstant: 50)
        [
            mockTitleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mockTitleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mockTitleView.topAnchor.constraint(equalTo: topAnchor),
            mockTitleViewHeight
        ].activate()
        self.mockTitleViewHeight = mockTitleViewHeight

        let titleSeparator = separator()
        mockTitleView.addSubview(titleSeparator)
        [
            titleSeparator.leadingAnchor.constraint(equalTo: mockTitleView.leadingAnchor),
            titleSeparator.trailingAnchor.constraint(equalTo: mockTitleView.trailingAnchor),
            titleSeparator.bottomAnchor.constraint(equalTo: mockTitleView.bottomAnchor),
            titleSeparator.heightAnchor.constraint(equalToConstant: 1)
        ].activate()
    }

    private func separator() -> UIView {
        let separator = UIView(frame: .zero)
        separator.backgroundColor = ColorProvider.Shade20
        return separator
    }
}
