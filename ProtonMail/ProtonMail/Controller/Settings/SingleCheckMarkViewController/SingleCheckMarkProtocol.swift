// swiftlint:disable:this file_name
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import UIKit

protocol SettingsSingleCheckMarkVMProtocol {
    var title: String { get }
    var sectionNumber: Int { get }
    var rowNumber: Int { get }
    var headerHeight: CGFloat { get }
    var headerTopPadding: CGFloat { get }
    var footerTopPadding: CGFloat { get }

    func getSectionHeader(of section: Int) -> NSAttributedString?
    func getSectionFooter(of section: Int) -> NSAttributedString?
    func getCellTitle(of indexPath: IndexPath) -> String?
    func getCellShouldShowSelection(of indexPath: IndexPath) -> Bool
    func selectItem(indexPath: IndexPath)
}

protocol SettingsSingleCheckMarkUIProtocol: UIViewController {
    func show(error: String)
    func reloadTable()
    func showLoading(shouldShow: Bool)
}
