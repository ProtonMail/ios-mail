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

import ProtonCore_UIFoundations

class NewOnboardView: UIView {
    let upperSpace = SubviewFactory.upperSpace
    let titleLabel = SubviewFactory.titleLabel
    let contentLabel = SubviewFactory.contentLabel
    let imageView = SubviewFactory.imageView

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        addSubview(upperSpace)
        upperSpace.addSubview(imageView)
        addSubview(titleLabel)
        addSubview(contentLabel)
    }

    private func setupViews() {
        let ratio: CGFloat = 398.0 / 656.0
        [
            upperSpace.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            upperSpace.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            upperSpace.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            upperSpace.heightAnchor.constraint(equalTo: heightAnchor, multiplier: ratio)
        ].activate()

        [
            imageView.topAnchor.constraint(equalTo: upperSpace.topAnchor, constant: 40.0),
            imageView.bottomAnchor.constraint(equalTo: upperSpace.bottomAnchor, constant: -32.0),
            imageView.leadingAnchor.constraint(equalTo: upperSpace.leadingAnchor, constant: 16.0),
            imageView.trailingAnchor.constraint(equalTo: upperSpace.trailingAnchor, constant: -16.0)
        ].activate()

        [
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 32.0),
            titleLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -32.0),
            titleLabel.heightAnchor.constraint(equalToConstant: 28),
            titleLabel.topAnchor.constraint(equalTo: upperSpace.bottomAnchor, constant: 64)
        ].activate()

        [
            contentLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 32.0),
            contentLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -32.0),
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12)
        ].activate()
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
}

private enum SubviewFactory {
    static var upperSpace: UIView {
        let view = UIView()
        return view
    }

    static var titleLabel: UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }

    static var contentLabel: UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }

    static var imageView: UIImageView {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
}
