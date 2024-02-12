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

import UIKit

/// The purpose of this class is to be able to use an activity indicator inside a cell.
final class InCellActivityIndicatorView: UIActivityIndicatorView {
    @available(*, unavailable, message: "This method does nothing, use `customStopAnimating` instead.")
    override func stopAnimating() {
        /*
         This method is called by the OS as a part of `prepareForReuse`.
         However, the animation is never restarted.
         The result is that the spinner is gone too soon, before the processing is complete.
         */
    }

    func customStopAnimating() {
        super.stopAnimating()
    }
}
