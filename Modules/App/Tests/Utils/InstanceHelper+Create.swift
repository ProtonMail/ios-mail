// Copyright (c) 2024 Proton Technologies AG
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

extension InstanceHelper {
    static func create<Object: AnyObject>(_ class: Object.Type, properties: [String: Any] = [:]) throws -> Object {
        guard let instance = InstanceHelper.createInstance(`class`, properties: properties) as? Object else {
            throw NSError(
                domain: "InstanceHelper",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Cannot create instance of \(`class`)"]
            )
        }

        return instance
    }
}
