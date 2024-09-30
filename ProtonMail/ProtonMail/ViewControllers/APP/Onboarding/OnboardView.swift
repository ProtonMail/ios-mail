//
//  OnboardView.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
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
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

import ProtonCoreUIFoundations
import UIKit

class OnboardView: UIView {
    let scrollView = SubviewsFactory.scrollView
    let pageControl = SubviewsFactory.pageControl
    let nextButton = SubviewsFactory.button
    let skipButton = SubviewsFactory.skipButton

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        addSubviews()
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func addSubviews() {
        addSubview(scrollView)
        addSubview(pageControl)
        addSubview(nextButton)
        addSubview(skipButton)
    }

    private func setUpLayout() {
        [
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -16.0)
        ].activate()

        [
            nextButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32.0),
            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32.0),
            nextButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -56.0),
            nextButton.heightAnchor.constraint(equalToConstant: 48.0)
        ].activate()

        [
            pageControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            pageControl.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 16.0),
            pageControl.heightAnchor.constraint(equalToConstant: 32.0)
        ].activate()

        [
            skipButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            skipButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            skipButton.heightAnchor.constraint(equalToConstant: 44.0),
            skipButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 64.0)
        ].activate()
    }
}

private enum SubviewsFactory {
    static var scrollView: UIScrollView {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.bounces = false
        return scrollView
    }

    static var pageControl: UIPageControl {
        let control = UIPageControl(frame: .zero)
        control.pageIndicatorTintColor = ColorProvider.InteractionWeak
        control.currentPageIndicatorTintColor = ColorProvider.InteractionNorm
        return control
    }

    static var button: ProtonButton {
        let button = ProtonButton(frame: .zero)
        button.setMode(mode: .solid)
        return button
    }

    static var skipButton: UIButton {
        let button = UIButton(frame: .zero)
        button.setTitleColor(ColorProvider.InteractionNorm, for: .normal)
        button.setTitle(LocalString._skip_btn_title, for: .normal)
        return button
    }
}
