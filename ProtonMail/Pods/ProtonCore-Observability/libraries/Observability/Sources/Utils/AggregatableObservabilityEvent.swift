//
//  AggregatableObservabilityEvent.swift
//  ProtonCore-Observability - Created on 31.01.23.
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

/// This struct is used for type erasure of the ObservabilityEvent
public struct AggregableObservabilityEvent: Encodable {

    private let internalEncode: (Encoder) throws -> Void
    private let internalCompare: (Any) -> Bool
    private let internalIncrement: () -> Void

    private final class Wrapped<T> {
        var value: T
        init(value: T) {
            self.value = value
        }
    }

    public init<Labels>(event: ObservabilityEvent<PayloadWithLabels<Labels>>) where Labels: Encodable & Equatable {
        let wrappedEvent: Wrapped<ObservabilityEvent<PayloadWithLabels<Labels>>> = .init(value: event)
        internalEncode = {
            try wrappedEvent.value.encode(to: $0)
        }
        internalIncrement = {
            wrappedEvent.value = wrappedEvent.value.increment()
        }
        internalCompare = { anyEvent in
            guard let typedEvent = anyEvent as? ObservabilityEvent<PayloadWithLabels<Labels>> else { return false }
            return wrappedEvent.value.name == typedEvent.name
                && wrappedEvent.value.data.labels == typedEvent.data.labels
                && wrappedEvent.value.version == typedEvent.version
        }
    }

    public func encode(to encoder: Encoder) throws {
        try internalEncode(encoder)
    }

    public func isSameAs<Payload>(event: ObservabilityEvent<Payload>) -> Bool where Payload: Encodable {
        internalCompare(event)
    }

    public func increment() {
        internalIncrement()
    }
}
