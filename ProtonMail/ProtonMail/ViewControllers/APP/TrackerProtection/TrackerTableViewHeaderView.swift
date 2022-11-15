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

class TrackerTableViewHeaderView: UITableViewHeaderFooterView {
    let providerNameLabel = SubviewFactory.providerNameLabel
    let trackerCountLabel = SubviewFactory.trackerCountLabel
    let expansionChevron = SubviewFactory.expansionChevron

    private var onExpansionToggled: (() -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView?.backgroundColor = .clear
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with trackerInfo: TrackerInfo, isExpanded: Bool, onExpansionToggled: @escaping () -> Void) {
        providerNameLabel.text = trackerInfo.provider

        trackerCountLabel.text = "\(trackerInfo.urls.count)"

        let chevron = isExpanded ? IconProvider.chevronUp : IconProvider.chevronDown
        expansionChevron.image = chevron

        self.onExpansionToggled = onExpansionToggled
    }

    private func setupSubviews() {
        let row = UIStackView(arrangedSubviews: [providerNameLabel, UIView(), trackerCountLabel, expansionChevron])
        row.spacing = 16
        contentView.addSubview(row)
        row.centerInSuperview()
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            row.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16)
        ])

        let expansionButton = UIButton()
        contentView.addSubview(expansionButton)
        expansionButton.fillSuperview()
        expansionButton.addTarget(self, action: #selector(expansionToggled), for: .touchUpInside)
    }

    @objc
    private func expansionToggled() {
        onExpansionToggled?()
    }
}

private enum SubviewFactory {
    static var providerNameLabel: UILabel {
        let label = UILabel()
        label.textColor = ColorProvider.TextNorm
        label.set(text: nil, preferredFont: .body)
        return label
    }

    static var trackerCountLabel: UILabel {
        let label = UILabel()
        label.backgroundColor = ColorProvider.InteractionNorm
        label.clipsToBounds = true
        label.set(text: "0", preferredFont: .footnote)
        label.textAlignment = .center
        label.textColor = ColorProvider.SidebarTextNorm

        label.sizeToFit()
        let height: CGFloat = label.frame.height
        label.layer.cornerRadius = height / 2
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: height),
            label.heightAnchor.constraint(equalTo: label.widthAnchor)
        ])

        return label
    }

    static var expansionChevron: UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorProvider.IconNorm
        return imageView
    }
}
