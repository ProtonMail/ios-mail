// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import Foundation

public final class ICalComponentReader: ICalComponentProtocol {
    public let component: OpaquePointer

    /// Stores the objects for they'll be deinit once we don't hold them
    private(set) var subComponents: [ICalComponentProtocol] = []
    /// Stores the objects for they'll be deinit once we don't hold them
    private(set) var properties: [ICalPropertyWriterProtocol] = []

    private var deinited: Bool = false

    public init(ics: String) {
        self.component = icalparser_parse_string(ics)
    }

    deinit {
        guard deinited == false else { return }
        icalcomponent_free(component)
        setDeinited()
    }

    public func setDeinited() {
        guard self.deinited == false else { return }

        self.deinited = true

        self.subComponents.forEach {
            $0.setDeinited()
        }
        self.properties.forEach {
            $0.setDeinited()
        }
    }
}
