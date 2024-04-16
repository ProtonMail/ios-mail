//
//  Created on 7/3/24.
//
//  Copyright (c) 2024 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

public protocol ProductMetricsMeasurable {
    var productMetrics: ProductMetrics { get }

    func measureOnViewDisplayed(additionalDimensions: [TelemetryDimension])
    func measureOnViewClosed()
    func measureOnViewClicked(
        item: String,
        additionalDimensions: [TelemetryDimension]
    )
    func measureOnViewFocused(
        item: String,
        additionalDimensions: [TelemetryDimension]
    )
    func measureAPIResult(
        action: TelemetryEventAction,
        additionalValues: [TelemetryValue],
        additionalDimensions: [TelemetryDimension]
    )
    func measureOnViewAction(
        action: TelemetryEventAction,
        additionalValues: [TelemetryValue],
        additionalDimensions: [TelemetryDimension]
    )
}

public extension ProductMetricsMeasurable {
    func measureOnViewDisplayed(additionalDimensions: [TelemetryDimension] = []) {
        let event = TelemetryEvent(
            source: .fe, screen: productMetrics.screen, action: .displayed,
            measurementGroup: productMetrics.group,
            values: [
                .timestamp(Float(Date().timeIntervalSince1970))
            ],
            dimensions: [
                .flow(productMetrics.flow)
            ] + additionalDimensions
        )
        reportEvent(event: event)
    }

    func measureOnViewClosed() {
        let event = TelemetryEvent(
            source: .user, screen: productMetrics.screen, action: .closed,
            measurementGroup: productMetrics.group,
            values: [
                .timestamp(Float(Date().timeIntervalSince1970))
            ],
            dimensions: [
                .flow(productMetrics.flow)
            ]
        )
        reportEvent(event: event)
    }

    func measureOnViewClicked(
        item: String,
        additionalDimensions: [TelemetryDimension] = []
    ) {
        let event = TelemetryEvent(
            source: .user, screen: productMetrics.screen, action: .clicked,
            measurementGroup: productMetrics.group,
            values: [
                .timestamp(Float(Date().timeIntervalSince1970))
            ],
            dimensions: [
                .flow(productMetrics.flow),
                .item(item)
            ] + additionalDimensions
        )
        reportEvent(event: event)
    }

    func measureOnViewFocused(
        item: String,
        additionalDimensions: [TelemetryDimension] = []
    ) {
        let event = TelemetryEvent(
            source: .user, screen: productMetrics.screen, action: .focused,
            measurementGroup: productMetrics.group,
            values: [
                .timestamp(Float(Date().timeIntervalSince1970))
            ],
            dimensions: [
                .flow(productMetrics.flow),
                .item(item)
            ] + additionalDimensions
        )
        reportEvent(event: event)
    }

    func measureAPIResult(
        action: TelemetryEventAction,
        additionalValues: [TelemetryValue] = [],
        additionalDimensions: [TelemetryDimension] = []
    ) {
        let event = TelemetryEvent(
            source: .be, screen: productMetrics.screen, action: action,
            measurementGroup: productMetrics.group,
            values: [
                .timestamp(Float(Date().timeIntervalSince1970))
            ] + additionalValues,
            dimensions: [
                .flow(productMetrics.flow)
            ] + additionalDimensions
        )
        reportEvent(event: event)
    }

    func measureOnViewAction(
        action: TelemetryEventAction,
        additionalValues: [TelemetryValue] = [],
        additionalDimensions: [TelemetryDimension] = []
    ) {
        let event = TelemetryEvent(
            source: .fe, screen: productMetrics.screen, action: action,
            measurementGroup: productMetrics.group,
            values: [
                .timestamp(Float(Date().timeIntervalSince1970))
            ],
            dimensions: [
                .flow(productMetrics.flow)
            ] + additionalDimensions
        )
        reportEvent(event: event)
    }

    private func reportEvent(event: TelemetryEvent) {
        Task {
            await TelemetryService.shared.report(event: event)
        }
    }
}
