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

import SwiftUI

/// Presenter responsible for controlling the visibility of the loading bar.
/// Works in conjunction with the loading bar view to provide smooth animations.
public final class LoadingBarPresenter: ObservableObject {
    @Published public private(set) var isVisible: Bool = false

    public init() {}

    /// Displays the loading bar immediately.
    /// The loading bar will appear and start animating as soon as this method is called.
    public func show() {
        isVisible = true
    }

    /// Hides the loading bar after the current animation cycle completes.
    /// Instead of hiding immediately, this allows the animation to reach 100% before hiding,
    /// ensuring a smooth visual experience for the user.
    public func hide() {
        isVisible = false
    }
}
