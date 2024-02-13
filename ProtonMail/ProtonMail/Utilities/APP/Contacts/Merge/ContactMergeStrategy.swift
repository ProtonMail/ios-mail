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

import Foundation

protocol ContactMergeStrategy {
    /// Indicates if the result of the merge function updates the device or the proton contact object that was passed as parameter
    var mergeDestination: ContactMergeDestination { get }

    /// Merges two contacts with  `mergeDestination` being the recipient of the changes.
    /// - Returns: returns 
    /// `true`: if there were differences and the information in `mergeDestination` was updated
    /// `false`: if not differences were detected between the contacts
    func merge(deviceContact: VCardObject, protonContact: ProtonVCards) throws -> Bool
}

enum ContactMergeDestination {
    case deviceContact
    case protonContact
}
