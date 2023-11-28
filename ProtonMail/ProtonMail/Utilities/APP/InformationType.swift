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

enum InformationType: Int, CaseIterable {
    case organization
    case nickname
    case title
    case anniversary
    case gender
    case url
    case birthday

    var desc: String {
        switch self {
        case .organization:
            return LocalString._contacts_add_org
        case .nickname:
            return LocalString._contacts_add_nickname
        case .title:
            return LocalString._contacts_add_title
        case .birthday:
            return LocalString._contacts_add_bd
        case .anniversary:
            return LocalString._contacts_add_anniversary
        case .gender:
            return LocalString._contacts_add_gender
        case .url:
            return LocalString._add_new_url
        }
    }

    var title: String {
        switch self {
        case .organization:
            return LocalString._contacts_info_organization
        case .nickname:
            return LocalString._contacts_info_nickname
        case .title:
            return LocalString._contacts_info_title
        case .birthday:
            return LocalString._contacts_info_birthday
        case .anniversary:
            return LocalString._contacts_info_anniversary
        case .gender:
            return LocalString._contacts_info_gender
        case .url:
            return LocalString._contacts_vcard_url_placeholder
        }
    }
}
