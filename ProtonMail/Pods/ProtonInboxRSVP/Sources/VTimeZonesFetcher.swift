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

import Combine
import ProtonCoreServices
import ProtonInboxICal

public enum VTimeZonesFetcherError: Error {
    case fetchingTimeZonesFailure(Error)
}

public struct VTimeZonesFetcher {
    private let vTimeZonesInfoProvider: VTimeZonesInfoProviding

    public init(vTimeZonesInfoProvider: VTimeZonesInfoProviding) {
        self.vTimeZonesInfoProvider = vTimeZonesInfoProvider
    }

    public func fetchVTimeZones(for event: ICalEvent) -> AnyPublisher<[String], Error> {
        let timeZoneIDs = event.allTimeZones
            .uniqued()
            .filter { $0 != TimeZone.GMT }
            .map(\.protonIdentifier)

        guard !timeZoneIDs.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        return vTimeZonesInfoProvider
            .vTimeZonesInfo(timeZoneIDs: timeZoneIDs)
            .mapError(VTimeZonesFetcherError.fetchingTimeZonesFailure)
            .map { response in response.timeZones.sorted(by: \.key, >).map(\.value) }
            .eraseToAnyPublisher()
    }
}

private extension ICalEvent {

    var allTimeZones: [TimeZone] {
        let exdatesTimeZoneIdentifiers = exdatesTimeZoneIdentifiers?.map(ProtonTimeZone.getTimeZone) ?? []

        return [
            startDateTimeZone,
            endDateTimeZone,
            recurrenceIDTimeZoneIdentifier.flatMap(ProtonTimeZone.getTimeZone)
        ].compactMap { $0 } + exdatesTimeZoneIdentifiers
    }

}
