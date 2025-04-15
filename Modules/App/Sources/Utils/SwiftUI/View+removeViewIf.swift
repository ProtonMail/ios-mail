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

import SwiftUI

extension View {

    /**
     Remove the view of the view hierarchy based on a condition.
    
     Example:
    
     ```swift
     Text(String(numAttachments))
       .removeViewIf( numAttachments == 0 )
     ```
    
     Before using this conditional view modifier take into account that any internal @State of the view can be lost
     */
    @ViewBuilder
    func removeViewIf(_ condition: Bool) -> some View {
        if condition {
            EmptyView()
        } else {
            self
        }
    }

}
