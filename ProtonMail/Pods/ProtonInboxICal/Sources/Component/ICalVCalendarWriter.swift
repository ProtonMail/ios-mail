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

/// The ICalVCalendarWriter is the component that facilitates writing VCalendar objects.
final class ICalVCalendarWriter: ICalComponentWriter {
    private let timestamp: () -> Date

    private let iCalVersion: String

    private let productVersion: String

    private let calendarScale: String

    var vcalendar: OpaquePointer {
        component
    }

    var prodID: String {
        return "-//Proton Technologies//iOSCalendar \(productVersion)//EN"
    }

    /// - Parameter timestamp: Date which is used for calculating the timestamp
    /// - Parameter productVersion: The product version. Typically the bundle version in our case
    /// - Parameter iCalVersion: The ical version as string
    /// - Parameter calendarScale: The calendar scale
    init(
        timestamp: @escaping () -> Date,
        productVersion: String = Constants.productVersion,
        iCalVersion: String = Constants.iCalVersion,
        calendarScale: String = Constants.scale
    ) {
        self.timestamp = timestamp
        self.productVersion = productVersion
        self.iCalVersion = iCalVersion
        self.calendarScale = calendarScale
        super.init(icalcomponent_new(ICAL_VCALENDAR_COMPONENT))
        _ = self.addRequiredHeaders()
    }

    // MARK: public func

    /// Returns `self` only when VEvent is built and added successfully.
    /// o.w., if `VEVent` is empty, this returns `nil`.
    /// - Note: This is better to observe what event not built successuly in case we need to support multiple VEvent in VCalendar.
    func addVEvent(model event: ICalEvent, _ type: ICalVEventWriter.BuildType) throws -> Self? {
        if let vevent = try ICalVEventWriter(event: event, timestamp: timestamp).build(type) {
            addSubComponent(vevent)
            return self
        }
        return nil
    }

    /// - SeeAlso: https://confluence.protontech.ch/display/CALENDAR/vTimezones
    func addVTimeZone(ics: String) -> Self {
        let object = ICalComponentReader(ics: ics)
        addSubComponent(object)
        return self
    }

    func addMethod(_ methodType: icalproperty_method) -> Self {
        addProperty(safe: icalproperty_new_method(methodType))
        return self
    }

    func addCalscale() -> Self {
        addProperty(safe: icalproperty_new_calscale(calendarScale))
        return self
    }

    // MARK: - private func and helpers

    private func addVersion() -> Self {
        addProperty(safe: icalproperty_new_version(iCalVersion))
        return self
    }

    private func addProdID() -> Self {
        // Since we don't enforce the prodID to be kept during editing, we will just generate a new one, using our prodID
        addProperty(safe: icalproperty_new_prodid(prodID))
        return self
    }

    private func addRequiredHeaders() -> Self {
        self
            .addProdID()
            .addVersion()
    }
}
