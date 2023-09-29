// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import Network

// sourcery: mock
protocol ConnectionMonitor: AnyObject {
    var currentPathProtocol: NWPathProtocol? { get }
    var pathUpdateClosure: ((_ newPath: NWPathProtocol) -> Void)? { get set }

    func start(queue: DispatchQueue)
    func cancel()
}

extension NWPathMonitor: ConnectionMonitor {
    var pathUpdateClosure: ((_ newPath: NWPathProtocol) -> Void)? {
        get {
            nil
        }
        set {
            pathUpdateHandler = newValue
        }
    }

    var currentPathProtocol: NWPathProtocol? {
        currentPath
    }
}

// sourcery: mock
protocol NWPathProtocol {
    var pathStatus: NWPath.Status? { get }
    var isPossiblyConnectedThroughVPN: Bool { get }

    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool
}

extension NWPathProtocol {
    var isPossiblyConnectedThroughVPN: Bool {
        usesInterfaceType(.other)
    }
}

extension NWPath: NWPathProtocol {
    var pathStatus: Status? {
        status
    }
}
