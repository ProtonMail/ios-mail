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

import UIKit

extension UIApplication {
    var topMostWindow: UIWindow? {
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            let windows = windowScene.windows.sorted(by: { $0.windowLevel > $1.windowLevel })
            #if DEBUG_ENTERPRISE
            // Because the window from the LifeTimeTracker.
            if let topWindow = windows.dropFirst().first {
                return topWindow
            }
            #else
            if let topWindow = windows.first {
                return topWindow
            }
            #endif
        }
        return nil
    }
}
