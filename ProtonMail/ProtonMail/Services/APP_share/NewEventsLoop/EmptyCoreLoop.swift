// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreEventsLoop

final class EmptyCoreLoop: CoreLoop {
    var delegate: CoreLoopDelegate?

    var loopID: String = .empty

    var latestEventID: String?

    typealias Response = EventCheckResponse

    func poll(sinceLatestEventID eventID: String, completion: @escaping (Result<EventCheckResponse, Error>) -> Void) {
        fatalError("Should not be used")
    }

    func process(response: EventCheckResponse, completion: @escaping (Result<Void, Error>) -> Void) {
        fatalError("Should not be used")
    }

    func onError(error: ProtonCoreEventsLoop.EventsLoopError) {
        fatalError("Should not be used")
    }
}
