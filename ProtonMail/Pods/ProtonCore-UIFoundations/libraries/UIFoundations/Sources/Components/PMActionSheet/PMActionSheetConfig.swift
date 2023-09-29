//
//  PMActionSheetConfig.swift
//  ProtonCore-UIFoundations - Created on 2023/1/22.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import Foundation
import UIKit

public final class PMActionSheetConfig {
    public static let shared: PMActionSheetConfig = PMActionSheetConfig()

    public var actionSheetBackgroundColor: UIColor = ColorProvider.BackgroundNorm
    /// Maximum actionSheet occupy scale when initialized
    public var actionSheetMaximumInitializeOccupy: CGFloat = 0.9 {
        didSet { assert(actionSheetMaximumInitializeOccupy >= 0 && actionSheetMaximumInitializeOccupy <= 1) }
    }
    public var actionSheetMaximumWidth: CGFloat = 414
    /// Radius for top-right and top-left corner
    public var actionSheetRadius: CGFloat = 10
    /// Button component text font
    public var buttonComponentFont: UIFont = .adjustedFont(forTextStyle: .body, weight: .semibold)
    /// Check mark icon color when selected
    public var checkMarkSelectedColor: UIColor = ColorProvider.BrandNorm
    /// Check mark icon color when unselected
    public var checkMarkUnSelectedColor: UIColor = ColorProvider.IconNorm
    /// Border color for grid cell
    public var gridBorderColor: UIColor = ColorProvider.InteractionWeak
    /// Default icon color for grid style
    public var gridIconColor: UIColor = ColorProvider.BrandNorm
    /// The spacing to use between lines of items in the grid.
    public var gridLineSpacing: CGFloat = 8
    /// Corner radius for grid cell
    public var gridRoundCorner: CGFloat = 10
    public var gridRowHeight: CGFloat = 64
    /// Default text color for grid style
    public var gridTextColor: UIColor = ColorProvider.BrandNorm
    /// Default text font for grid style
    public var gridTextFont: UIFont = .adjustedFont(forTextStyle: .caption2)
    /// Default header view height, the real height could change due to dynamic font size
    public var headerViewHeight: CGFloat = 72
    /// Default header view item's icon color
    public var headerViewItemIconColor: UIColor = ColorProvider.IconNorm
    /// Default header view item's icon size
    public var headerViewItemIconSize: CGSize = CGSize(width: 40, height: 40)
    /// Default header view item's text color
    public var headerViewItemTextColor: UIColor = ColorProvider.BrandNorm
    /// Default header view subtitle font
    public var headerViewSubtitleFont: UIFont = .adjustedFont(forTextStyle: .caption1)
    /// Default header view subtitle text color
    public var headerViewSubtitleTextColor: UIColor = ColorProvider.TextWeak
    /// Default header view title font (without subtitle case)
    public var headerViewTitleFontWOSubtitle: UIFont = .adjustedFont(forTextStyle: .body, weight: .semibold)
    /// Default header view title font (with subtitle case)
    public var headerViewTitleFontWithSubtitle: UIFont = .adjustedFont(forTextStyle: .subheadline, weight: .semibold)
    /// Icon component default icon color
    public var iconComponentColor: UIColor = ColorProvider.IconNorm
    /// Icon component default icon size
    public var iconComponentSize: CGSize = .init(width: 24, height: 24)
    /// Horizontal cell's indentation width
    public var indentationWidth: CGFloat = 24
    /// Designer is doing new sheet style, not finalized yet 
    public var isNewFigmaTheme: Bool = false
    public var panStyle: PanStyle = .v1
    public var plainCellBackgroundColor: UIColor = ColorProvider.BackgroundNorm
    /// Default cell height for plain cell
    /// Related group styles are `.clickable`, `.singleSelection`, `.multiSelection`, `.singleSelectionNewStyle`, `.multiSelectionNewStyle`
    public var plainCellHeight: CGFloat = 56
    public var sectionHeaderBackground: UIColor = ColorProvider.BackgroundNorm
    /// Group title font
    public var sectionHeaderFont: UIFont = .adjustedFont(forTextStyle: .subheadline)
    /// Group title view height, the real value could change due to dynamic font size
    public var sectionHeaderHeight: CGFloat = 56
    /// Group title default text color
    public var sectionHeaderTextColor: UIColor = ColorProvider.TextWeak
    /// Text component default text font
    public var textComponentFont: UIFont = .adjustedFont(forTextStyle: .subheadline)
    /// Text component default text color
    public var textComponentTextColor: UIColor = ColorProvider.TextNorm
    /// Default cell height for toggle cell
    /// Related group styles is `.toggle`
    public var toggleCellHeight: CGFloat = 56
    /// UISwitch tint color for on state
    public var toggleOnTintColor: UIColor = ColorProvider.BrandNorm
    /// Text color for two column style's right text
    public var twoColumnRightTextColor: UIColor = ColorProvider.TextHint
}

extension PMActionSheetConfig {
    public enum PanStyle {
        /// Action sheet will expand to actionSheetMaximumInitializeOccupy
        /// Can drag down to dismiss
        /// Can't drat top to expand more
        case v1
        /// Action sheet will expand to actionSheetMaximumInitializeOccupy
        /// Can drag down or top
        case v2
    }
}

#endif
