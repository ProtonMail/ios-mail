//
//  PMActionSheetHeaderModel.swift
//  ProtonCore-UIFoundations - Created on 20/08/2020.
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

public struct PMActionSheetHeaderModel {
    public let title: String
    public let subtitle: String?
    public let leftItem: PMActionSheetPlainItem?
    public let rightItem: PMActionSheetPlainItem?
    public let hasSeparator: Bool

    public init(title: String, subtitle: String?, leftItem: PMActionSheetPlainItem?, rightItem: PMActionSheetPlainItem?, hasSeparator: Bool) {
        self.title = title
        self.subtitle = subtitle
        self.leftItem = leftItem
        self.rightItem = rightItem
        self.hasSeparator = hasSeparator
    }
}

extension PMActionSheetHeaderModel {
    public static func makeView(from model: PMActionSheetHeaderModel?) -> PMActionSheetHeaderView? {
        guard let model = model else { return nil }
        return PMActionSheetHeaderView(title: model.title, subtitle: model.subtitle, leftItem: model.leftItem, rightItem: model.rightItem, hasSeparator: model.hasSeparator)
    }
}
