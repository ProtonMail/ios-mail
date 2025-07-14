// Copyright (c) 2025 Proton Technologies AG
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

import SwiftUI

extension DS {
    public enum SFSymbol: String, Sendable {
        case arrowUpRightSquare = "arrow.up.right.square"
        case checkmark = "checkmark"
        case checkmarkSquare = "checkmark.square"
        case chevronLeft = "chevron.backward"
        case chevronRight = "chevron.right"
        case chevronUpChevronDown = "chevron.up.chevron.down"
        case deleteLeft = "delete.left"
        case lock = "lock"
        case magnifier = "magnifyingglass"
        case rectanglePortraitAndArrowRight = "rectangle.portrait.and.arrow.right"
        case square = "square"
        case star = "star"
        case starFilled = "star.fill"
        case starSlash = "star.slash"
        case suitcase = "suitcase"
        case sunMax = "sun.max"
        case sunLeftHalfFilled = "sun.lefthalf.filled"
        case xmark = "xmark"
        case eye = "eye"
        case eyeSlash = "eye.slash"
        case forward = "arrowshape.turn.up.forward"
        case reply = "arrowshape.turn.up.backward"
        case replyAll = "arrowshape.turn.up.backward.2"
    }
}

extension Image {

    public init(symbol: DS.SFSymbol) {
        self.init(systemName: symbol.rawValue)
    }

}

extension UIImage {

    public convenience init(symbol: DS.SFSymbol) {
        self.init(systemName: symbol.rawValue)!
    }

}
