// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Combine
import Foundation

public typealias DispatchQueueScheduler = AnyScheduler<DispatchQueue.SchedulerTimeType>

public class AnyScheduler<SchedulerTimeType>: Scheduler
where SchedulerTimeType: Strideable, SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {
    public typealias SchedulerOptions = Never

    public init<S: Scheduler>(_ scheduler: S) where S.SchedulerTimeType == SchedulerTimeType {
        _now = { scheduler.now }
        _minimumTolerance = { scheduler.minimumTolerance }
        _schedule_action = { action in scheduler.schedule(options: nil, action) }
        _schedule_after_tolerance_action = { date, tolerance, action in
            scheduler.schedule(after: date, tolerance: tolerance, options: nil, action)
        }
        _schedule_after_interval_tolerance_action = { date, interval, tolerance, action in
            scheduler.schedule(after: date, interval: interval, tolerance: tolerance, options: nil, action)
        }
    }

    // MARK: - Scheduler

    public var now: SchedulerTimeType { _now() }
    public var minimumTolerance: SchedulerTimeType.Stride { _minimumTolerance() }

    public func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        _schedule_action(action)
    }

    public func schedule(
        after date: SchedulerTimeType,
        tolerance: SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) {
        _schedule_after_tolerance_action(date, tolerance, action)
    }

    public func schedule(
        after date: SchedulerTimeType,
        interval: SchedulerTimeType.Stride,
        tolerance: SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) -> Cancellable {
        _schedule_after_interval_tolerance_action(date, interval, tolerance, action)
    }

    // MARK: - Private

    private let _now: () -> SchedulerTimeType
    private let _minimumTolerance: () -> SchedulerTimeType.Stride
    private let _schedule_action: (@escaping () -> Void) -> Void
    private let _schedule_after_tolerance_action:
        (
            SchedulerTimeType,
            SchedulerTimeType.Stride,
            @escaping () -> Void
        ) -> Void
    private let _schedule_after_interval_tolerance_action:
        (
            SchedulerTimeType,
            SchedulerTimeType.Stride,
            SchedulerTimeType.Stride,
            @escaping () -> Void
        ) -> Cancellable
}
