//
//  ObservabilityAggregator.swift
//  ProtonCore-Observability - Created on 02.02.23.
//
//  Copyright (c) 2023 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import ProtonCoreUtilities

protocol ObservabilityAggregator {
    var aggregatedEvents: Atomic<[AggregableObservabilityEvent]> { get }
    func aggregate<Labels: Encodable & Equatable>(event: ObservabilityEvent<PayloadWithLabels<Labels>>)
    func clear()
}

class ObservabilityAggregatorImpl: ObservabilityAggregator {

    var aggregatedEvents = Atomic<[AggregableObservabilityEvent]>([])

    func aggregate<Labels: Encodable & Equatable>(event: ObservabilityEvent<PayloadWithLabels<Labels>>) {
        guard let index = aggregatedEvents.value.firstIndex(where: { $0.isSameAs(event: event) }) else {
            aggregatedEvents.mutate { events in
                events.append(.init(event: event))
            }
            return
        }
        aggregatedEvents.mutate { events in
            events[index].increment()
        }
    }

    func clear() {
        aggregatedEvents.mutate { events in
            events.removeAll()
        }
    }
}
