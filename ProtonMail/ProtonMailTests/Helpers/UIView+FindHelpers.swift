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

import UIKit

extension UIView {

    public func find<View: UIView>(_ viewType: View.Type, by matcher: (View) -> Bool) -> View? {
        findAll(View.self).first(where: matcher)
    }

    public func find<View: UIView, Property: Equatable>(
        for value: Property,
        by keyPath: KeyPath<View, Property>
    ) -> View? {
        findAll(View.self).first { $0[keyPath: keyPath] == value }
    }

    public func findFirst<View: UIView>(_ viewType: View.Type) -> View? {
        findAll(View.self).first
    }

    public func findAll<View: UIView>(_ viewType: View.Type) -> [View] {
        recursiveSubviews.compactMap { $0 as? View }
    }

    public var recursiveSubviews: [UIView] {
        subviews + subviews.flatMap(\.recursiveSubviews)
    }

}

public func hasMatchingImage(image expectedButtonImage: UIImage) -> (UIButton) -> Bool {
    return { button in
        button.image(for: .normal)?.pngData() == expectedButtonImage.pngData()
    }
}
