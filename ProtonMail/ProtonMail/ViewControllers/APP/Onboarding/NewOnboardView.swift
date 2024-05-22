//
//  NewOnboardView.swift
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

class NewOnboardView: UIView {
    let scrollView = SubviewFactory.scrollView
    let container = SubviewFactory.container
    let greyView = SubviewFactory.greyView
    let upperSpace = SubviewFactory.upperSpace
    let titleLabel = SubviewFactory.titleLabel
    let contentLabel = SubviewFactory.contentLabel
    let imageView = SubviewFactory.imageView
    private let maximumWidth: CGFloat = 375

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        addSubview(greyView)
        addSubview(scrollView)
        scrollView.addSubview(container)
        container.addSubview(upperSpace)
        upperSpace.addSubview(imageView)
        container.addSubview(titleLabel)
        container.addSubview(contentLabel)
    }

    private func setupViews() {
        setUpGreyViewConstraints()
        setUpScrollViewConstraints()
        setUpContainerConstraints()
        setUpUpperSpaceConstraints()
        setUpImageViewConstraints()
        setUpTitleLabelConstraints()
        setUpContentLabelConstraints()
    }

    func config(_ data: Onboarding) {
        imageView.image = data.image
        var headline = FontManager.Headline
        headline[.font] = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.attributedText = data.title.apply(style: headline.alignment(.center))
        var defaultAttr = FontManager.Default
        defaultAttr[.font] = UIFont.systemFont(ofSize: 17)
        contentLabel.attributedText = data.description.apply(style: defaultAttr.alignment(.center))
    }

    private func setUpGreyViewConstraints() {
        [
            greyView.topAnchor.constraint(equalTo: topAnchor),
            greyView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            greyView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            greyView.heightAnchor.constraint(equalToConstant: 100)
        ].activate()
    }

    private func setUpScrollViewConstraints() {
        [
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ].activate()
    }

    private func setUpContainerConstraints() {
        [
            container.topAnchor.constraint(equalTo: scrollView.topAnchor),
            container.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            container.heightAnchor.constraint(equalTo: scrollView.heightAnchor).setPriority(as: .init(999))
        ].activate()
    }

    private func setUpUpperSpaceConstraints() {
        let ratio: CGFloat = 398.0 / 656.0
        [
            upperSpace.topAnchor.constraint(equalTo: container.topAnchor),
            upperSpace.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            upperSpace.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            upperSpace.heightAnchor.constraint(equalTo: heightAnchor, multiplier: ratio)
        ].activate()
    }

    private func setUpImageViewConstraints() {
        [
            imageView.topAnchor.constraint(equalTo: upperSpace.topAnchor, constant: 40.0),
            imageView.bottomAnchor.constraint(equalTo: upperSpace.bottomAnchor, constant: -32.0),
            imageView.leadingAnchor.constraint(equalTo: upperSpace.leadingAnchor, constant: 16.0),
            imageView.trailingAnchor.constraint(equalTo: upperSpace.trailingAnchor, constant: -16.0)
        ].activate()
    }

    private func setUpTitleLabelConstraints() {
        [
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 32.0),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -32.0),
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: maximumWidth),
            titleLabel.heightAnchor.constraint(equalToConstant: 28),
            titleLabel.topAnchor.constraint(equalTo: upperSpace.bottomAnchor, constant: 16)
        ].activate()
    }

    private func setUpContentLabelConstraints() {
        [
            contentLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            contentLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 32.0),
            contentLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -32.0),
            contentLabel.widthAnchor.constraint(lessThanOrEqualToConstant: maximumWidth),
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            contentLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -8)
        ].activate()
    }
}

private enum SubviewFactory {
    static var scrollView: UIScrollView {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }

    static var container: UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear
        return container
    }

    static var greyView: UIView {
        let view = UIView()
        let trait = UITraitCollection(userInterfaceStyle: .light)
        view.backgroundColor = ColorProvider.BackgroundSecondary.resolvedColor(with: trait)
        return view
    }

    static var upperSpace: UIView {
        let view = UIView()
        let trait = UITraitCollection(userInterfaceStyle: .light)
        view.backgroundColor = ColorProvider.BackgroundSecondary.resolvedColor(with: trait)
        return view
    }

    static var titleLabel: UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    static var contentLabel: UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    static var imageView: UIImageView {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
}
