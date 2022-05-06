// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
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
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import Network

protocol ConnectionMonitor: AnyObject {
    @available(iOS 12.0, *)
    var currentNWPath: NWPath? { get }
    @available(iOS 12.0, *)
    var pathUpdateHandler: ((_ newPath: NWPath) -> Void)? { get set }

    func start(queue: DispatchQueue)
    func cancel()
}

@available(iOS 12.0, *)
extension NWPathMonitor: ConnectionMonitor {
    var currentNWPath: NWPath? {
        return currentPath
    }
}

class ConnectionMonitorFactory {
    static func makeMonitor() -> ConnectionMonitor? {
        if #available(iOS 12, *) {
            return NWPathMonitor()
        } else {
            return nil
        }
    }
}
