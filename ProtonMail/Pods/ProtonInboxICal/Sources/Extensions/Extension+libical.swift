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

/**
 icalcomponent_add_property_clone is a wrapper around icalcomponent_add_property

 Cloning of the icalproperty object will be performed before adding it to the icalcomponent
 */
func icalcomponent_add_property_clone(_ icalComponent: OpaquePointer, _ icalProperty: OpaquePointer) {
    icalcomponent_add_property(icalComponent, icalproperty_clone(icalProperty))
}

/**
 icalcomponent_add_component_clone is a wrapper around icalcomponent_add_component

 Cloning of the icalcomponent object will be performed before adding it to the icalcomponent
 */
func icalcomponent_add_component_clone(_ icalComponentParent: OpaquePointer, _ icalComponentChild: OpaquePointer) {
    icalcomponent_add_component(icalComponentParent, icalcomponent_clone(icalComponentChild))
}
