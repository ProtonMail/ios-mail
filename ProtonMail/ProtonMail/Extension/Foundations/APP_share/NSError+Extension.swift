//
//  NSError+Extension.swift
//  Proton Mail
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

import Foundation
import ProtonCore_Services

extension NSError {

    var isBadVersionError: Bool {
        // These two error codes are badAppVersion and badApiVersion
        // But the ProtonCore doesn't have it
        // it should use library constant after library update
        return self.code == 5_003 || self.code == 5_005
    }

    var isStorageExceeded: Bool {
        return self.code == 2_011
    }
}
