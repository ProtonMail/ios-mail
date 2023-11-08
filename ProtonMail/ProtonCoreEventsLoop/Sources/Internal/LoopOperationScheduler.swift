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

struct LoopOperationScheduler<Loop: EventsLoop> {
    let loop: Loop
    let order: Int
    let createOperationQueue: () -> OperationQueue

    func addOperation(to queue: OperationQueue) {
        let operation = LoopOperation(
            loop: loop,
            onDidReceiveMorePages: { addOperation(to: queue) },
            createOperationQueue: createOperationQueue
        )

        queue.addOperation(operation)
    }
}
