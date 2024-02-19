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

private struct ICSEventParsingModel {
    var uid: String?
}

/// A light parser for extracting events data from a given iCalendar (ICS) string.
/// More details about the ICS format can be found in [RFC 2445](https://www.ietf.org/rfc/rfc2445.txt).
public final class ICSEventParser {
    public init() {

    }

    private let eventComponentName = ICSComponent.event.name

    /// Parses the given ICS string and returns an array of ICSEvent objects.
    ///
    /// - Parameter icsString: The ICS string to parse.
    /// - Returns: An array of ICSEvent objects parsed from the input ICS string.
    public func parse(icsString: String) -> [ICSEvent] {
        var events: [ICSEvent] = []
        var currentEvent: ICSEventParsingModel?

        for icsLine in icsString.components(separatedBy: .newlines) {
            guard let icsEntry = iscEntry(from: icsLine) else {
                continue
            }

            switch icsEntry.property {
            case .uid:
                currentEvent?.uid = icsEntry.value
            case .begin where icsEntry.value == eventComponentName:
                currentEvent = ICSEventParsingModel()
            case .end where icsEntry.value == eventComponentName:
                if let icsEvent = currentEvent?.toICSEvent() {
                    events.append(icsEvent)
                }
                currentEvent = nil
            default:
                continue
            }
        }

        return events
    }

    /// Extracts an ICSEntry from a given iCalendar line.
    ///
    /// - Parameter icsLineString: The ICS line to process.
    /// - Returns: An optional ICSEntry object.
    private func iscEntry(from icsLineString: String) -> ICSEntry? {
        let lineComponents = icsLineString
            .components(separatedBy: ":")
            .map { component in component.trimmingCharacters(in: .whitespaces) }

        guard
            lineComponents.count == 2,
            let property = lineComponents.first.flatMap(icsProperty(from:)),
            let value = lineComponents.last
        else {
            return nil
        }

        return ICSEntry(property: property, value: value)
    }

    /// Converts a string representation of an ICS property to an ICSProperty enumeration.
    ///
    /// - Parameter input: The input string to convert, possibly containing optional additional parameters.
    /// - Returns: An optional ICSProperty enumeration. If the input string contains optional parameters,
    ///   only the main property is considered, and additional parameters are skipped.
    ///
    /// The `icsProperty` method is designed to extract the main property from a string representation of an ICS property,
    /// ignoring any optional additional parameters that may be present. It splits the input string using semicolons (;)
    /// and considers only the first part as the main property value. Any subsequent parts are ignored, allowing the method
    /// to focus on the primary property type.
    ///
    /// Example:
    /// ```
    /// let input = "SUMMARY;LANGUAGE=en"
    /// let icsProperty = icsProperty(from: input)
    /// print(icsProperty) // Output: .summary
    /// ```
    private func icsProperty(from input: String) -> ICSProperty? {
        input
            .components(separatedBy: ";")
            .first
            .flatMap(ICSProperty.init(rawValue:))

    }

}

private extension ICSEventParsingModel {

    func toICSEvent() -> ICSEvent? {
        uid.flatMap(ICSEvent.init)
    }

}
