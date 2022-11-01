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

import Foundation

enum ContactGroupEditError: Error {
    case noEmailInGroup
    case noNameForGroup

    case updateFailed

    case cannotGetCoreDataContext

    case InternalError
    case TypeCastingError
}

extension ContactGroupEditError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noEmailInGroup:
            return LocalString._contact_groups_no_email_selected
        case .noNameForGroup:
            return LocalString._contact_groups_no_name_entered
        case .InternalError:
            return LocalString._internal_error
        case .TypeCastingError:
            return LocalString._type_casting_error

        case .updateFailed:
            return LocalString._contact_groups_api_update_error
        case .cannotGetCoreDataContext:
            return LocalString._cannot_get_coredata_context
        }
    }
}
