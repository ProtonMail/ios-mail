// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and ProtonCore.
//
// ProtonCore is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonCore is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonCore. If not, see https://www.gnu.org/licenses/.

import Foundation

public protocol EventsLoop: AnyObject {
    associatedtype Response: EventPage

    func poll(sinceLatestEventID eventID: String, completion: @escaping (Result<Response, Error>) -> Void)
    func process(response: Response, completion: @escaping (Result<Void, Error>) -> Void)
    func onError(error: EventsLoopError)

    var loopID: String { get }
    var latestEventID: String? { get set }
}
