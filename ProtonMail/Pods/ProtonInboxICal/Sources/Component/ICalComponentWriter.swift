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

public class ICalComponentWriter: ICalComponentProtocol {
    public let component: OpaquePointer

    /// Stores the objects for they'll be deinit once we don't hold them
    private(set) var subComponents: [ICalComponentProtocol] = []

    /// Stores the objects for they'll be deinit once we don't hold them
    private(set) var properties: [ICalPropertyWriterProtocol] = []

    private var deinited: Bool = false

    init(_ component: OpaquePointer) {
        self.component = component
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

    // MARK: Helper

    /// Will store the component pointer inside the iCalComponentWriter class and keep the object the same
    @discardableResult
    func addSubComponent(_ object: ICalComponentProtocol) -> ICalComponentProtocol {
        self.subComponents.append(object)
        icalcomponent_add_component(self.component, object.component)
        return object
    }

    /// Will store the component pointer within a newly created iCalComponentWriter class to maintain the pointer
    /// ### Notes
    /// One should not call this when they wants to maintain the pointer themselves
    @discardableResult
    func addSubComponent(safe subComponent: OpaquePointer) -> ICalComponentWriter {
        let object = ICalComponentWriter(subComponent)
        _ = self.addSubComponent(object)
        return object
    }

    @discardableResult
    func addProperty(safe property: OpaquePointer) -> ICalPropertyWriter {
        let object = ICalPropertyWriter(property)
        properties.append(object)
        icalcomponent_add_property(self.component, property)
        return object
    }

    /// Will store the property pointer inside the iCalPropertyWriter class and keep the object the same
    @discardableResult
    func addProperty(_ object: ICalPropertyWriter) -> ICalPropertyWriter {
        self.properties.append(object)
        icalcomponent_add_property(self.component, object.property)
        return object
    }

    var isEmpty: Bool {
        self.subComponents.isEmpty && self.properties.isEmpty
    }
}
