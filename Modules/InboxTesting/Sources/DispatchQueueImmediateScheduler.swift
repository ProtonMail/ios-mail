// Copyright (c) 2025 Proton Technologies AG
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

public class DispatchQueueImmediateScheduler: Scheduler {
    public typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
    public typealias SchedulerOptions = DispatchQueue.SchedulerOptions

    public init() {
        _now = { DispatchQueue.SchedulerTimeType(DispatchTime(uptimeNanoseconds: 1)) }
        _minimumTolerance = { .zero }
    }

    // MARK: - Scheduler

    public var now: DispatchQueue.SchedulerTimeType { _now() }
    public var minimumTolerance: DispatchQueue.SchedulerTimeType.Stride { _minimumTolerance() }

    public func schedule(options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
        action()
    }

    public func schedule(
        after date: DispatchQueue.SchedulerTimeType,
        tolerance: DispatchQueue.SchedulerTimeType.Stride,
        options: DispatchQueue.SchedulerOptions?,
        _ action: @escaping () -> Void
    ) {
        action()
    }

    public func schedule(
        after date: DispatchQueue.SchedulerTimeType,
        interval: DispatchQueue.SchedulerTimeType.Stride,
        tolerance: DispatchQueue.SchedulerTimeType.Stride,
        options: DispatchQueue.SchedulerOptions?,
        _ action: @escaping () -> Void
    ) -> Cancellable {
        action()
        return AnyCancellable {}
    }

    // MARK: - Private

    private let _now: () -> DispatchQueue.SchedulerTimeType
    private let _minimumTolerance: () -> DispatchQueue.SchedulerTimeType.Stride
}
