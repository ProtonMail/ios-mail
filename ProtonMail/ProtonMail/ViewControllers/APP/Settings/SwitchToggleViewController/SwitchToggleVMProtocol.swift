// Copyright (c) 2022 Proton Technologies AG
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

import Foundation
import struct UIKit.CGFloat

protocol SwitchToggleVMProtocol {
    var input: SwitchToggleVMInput { get }
    var output: SwitchToggleVMOutput { get }
}

protocol SwitchToggleVMInput {
    typealias ToggleCompletion = (NSError?) -> Void

    func toggle(for indexPath: IndexPath, to newStatus: Bool, completion: @escaping ToggleCompletion)
}

protocol SwitchToggleVMOutput {
    var title: String { get }
    var sectionNumber: Int { get }
    var rowNumber: Int { get }
    var headerTopPadding: CGFloat { get }
    var footerTopPadding: CGFloat { get }

    func cellData(for indexPath: IndexPath) -> (title: String, status: Bool)?
    func sectionHeader(of section: Int) -> String?
    func sectionFooter(of section: Int) -> String?
}
