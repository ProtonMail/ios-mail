// Copyright (c) 2023 Proton Technologies AG
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

final class OfficialBadge: PaddingLabel {
    init() {
        super.init(withInsets: 2, 2, 6, 6)

        self.translatesAutoresizingMaskIntoConstraints = false

        backgroundColor = ColorProvider.BackgroundSecondary

        set(
            text: L11n.OfficialBadge.title,
            preferredFont: .footnote,
            weight: .semibold,
            textColor: ColorProvider.TextAccent
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        setCornerRadius(radius: frame.height / 2)
    }
}

final class OfficialBadgeComponent: PMActionSheetComponent {
    typealias Element = OfficialBadge
    // [up, right, bottom, left]
    let edge: [CGFloat?]
    let offset: UIOffset?

    init(edge: [CGFloat?], offset: UIOffset? = nil) {
        self.edge = edge
        self.offset = offset
    }

    func makeElement() -> OfficialBadge {
        let badge = OfficialBadge()
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)
        return badge
    }
}
