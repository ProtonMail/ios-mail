//
//  SingleMessageView.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

import ProtonCore_UIFoundations

class SingleMessageView: UIView {

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        addSubviews()
        setUpLayout()
        accessibilityElements = [scrollView, toolBar]
    }

    let scrollView = SubviewsFactory.scrollView
    let stackView = UIStackView.stackView(axis: .vertical)
    let titleLabel = SubviewsFactory.titleLabel
    let navigationSeparator = SubviewsFactory.smallSeparatorView
    let smallTitleHeaderSeparatorView = SubviewsFactory.smallSeparatorView
    let bigSeparatorView = SubviewsFactory.bigSeparatorView
    let contentContainer = UIView()
    let toolBar = SubviewsFactory.toolBar

    private func addSubviews() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)

        addSubview(navigationSeparator)

        stackView.addArrangedSubview(StackViewContainer(view: titleLabel, leading: 24, trailing: -24, bottom: -8))
        stackView.addArrangedSubview(smallTitleHeaderSeparatorView)
        stackView.addArrangedSubview(bigSeparatorView)
        stackView.addArrangedSubview(contentContainer)
        addSubview(toolBar)
    }

    private func setUpLayout() {
        let bottomPadding = UIDevice.safeGuide.bottom
        let height = 56.0 + bottomPadding

        [
            toolBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            toolBar.heightAnchor.constraint(equalToConstant: height)
        ].activate()

        [
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: toolBar.topAnchor)
        ].activate()

        [
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: widthAnchor)
        ].activate()

        [smallTitleHeaderSeparatorView.heightAnchor.constraint(equalToConstant: 1)].activate()
        [bigSeparatorView.heightAnchor.constraint(equalToConstant: 4)].activate()

        [
            navigationSeparator.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            navigationSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            navigationSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
            navigationSeparator.heightAnchor.constraint(equalToConstant: 1)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var scrollView: UIScrollView {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.alwaysBounceVertical = true
        scrollView.bounces = true
        return scrollView
    }

    static var smallSeparatorView: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.Shade20
        return view
    }

    static var bigSeparatorView: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.BackgroundSecondary
        return view
    }

    static var titleLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        return label
    }

    static var toolBar: PMToolBarView {
        let toolBar = PMToolBarView()
        return toolBar
    }
}
