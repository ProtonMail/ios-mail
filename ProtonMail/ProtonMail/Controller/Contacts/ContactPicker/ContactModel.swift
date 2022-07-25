//
//  ContactModel.swift
//  Proton Mail - Created on 4/26/18.
//
//
//  Copyright (c) 2019 Proton AG
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
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_Services

typealias LockCheckComplete = (_ lock: UIImage?, _ lockType: Int) -> Void

@objc enum ContactPickerModelState: Int, Hashable {
    case contact = 1
    case contactGroup = 2
}

protocol ContactPickerModelProtocol: NSCopying {
    var modelType: ContactPickerModelState { get }
    var contactTitle: String { get }

    // @optional
    var displayName: String? { get }
    var displayEmail: String? { get }
    var contactSubtitle: String? { get }
    var contactImage: UIImage? { get }
    var color: String? { get }
    var hasPGPPined: Bool { get }
    var hasNonePM: Bool { get }

    func equals(_ others: ContactPickerModelProtocol) -> Bool
}
