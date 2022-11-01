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

import UIKit

final class ExpandedTagFlowLayout: UICollectionViewFlowLayout {
    // Left alignment
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        var attributesArrayCopy = [UICollectionViewLayoutAttributes]()

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        attributes?.forEach { layoutAttributes in
            guard let attributesCopy = layoutAttributes.copy() as? UICollectionViewLayoutAttributes else { return }
            if attributesCopy.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }

            attributesCopy.frame.origin.x = leftMargin

            leftMargin += attributesCopy.frame.width + minimumInteritemSpacing
            maxY = max(attributesCopy.frame.maxY, maxY)
            attributesArrayCopy.append(attributesCopy)
        }
        return attributesArrayCopy
    }
}
