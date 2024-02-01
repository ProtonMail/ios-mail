//
//  AlertBoxViewModel.swift
//  ProtonCorePaymentsUI - Created on 25.01.24.
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

import Foundation

struct AlertBoxViewModel {
    let title = NSLocalizedString("Your storage is full", comment: "title of a warning informating that the storage is full")
    let description = NSLocalizedString("Upgrade your plan to continue to use your account without interruptions.", comment: "")
    let buttonTitle = NSLocalizedString("Get more storage", comment: "Title of a button to get more storage")
}
