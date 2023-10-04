//
//  PayloadWithValueAndLabels.swift
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

public typealias PayloadWithLabels<Labels> = PayloadWithValueAndLabels<Int, Labels> where Labels: Encodable

public struct PayloadWithValueAndLabels<Value, Labels>: Encodable where Value: Encodable, Labels: Encodable {
    let value: Value
    let labels: Labels

    enum CodingKeys: String, CodingKey {
        case value = "Value"
        case labels = "Labels"
    }
}

extension ObservabilityEvent {
    init<Labels>(name: String, labels: Labels, version: ObservabilityEventVersion) where Payload == PayloadWithLabels<Labels>, Labels: Encodable {
        self.init(name: name, version: version, data: .init(value: version.rawValue, labels: labels))
    }
}

extension ObservabilityEvent {
    init<Labels>(name: String, value: Int, labels: Labels) where Payload == PayloadWithLabels<Labels>, Labels: Encodable {
        self.init(name: name, version: .v1, data: .init(value: value, labels: labels))
    }
}

extension ObservabilityEvent {
    init<Labels>(name: String, labels: Labels) where Payload == PayloadWithLabels<Labels>, Labels: Encodable {
        self.init(name: name, version: .v1, data: .init(value: 1, labels: labels))
    }
}

extension ObservabilityEvent {
    func increment<Labels>() -> Self where Payload == PayloadWithValueAndLabels<Int, Labels>, Labels: Encodable {
        .init(name: name, version: version, data: .init(value: data.value + 1, labels: data.labels))
    }
}
