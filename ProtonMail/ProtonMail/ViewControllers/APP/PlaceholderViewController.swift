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

// this view controller is placed into AppWindow only until it is correctly loaded from storyboard or correctly restored with use of MainKey
final class PlaceholderViewController: UIViewController {
    var color: UIColor = .blue

    convenience init(color: UIColor) {
        self.init()
        self.color = color
    }

    override func loadView() {
        view = UINib(nibName: "LaunchScreen", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
#if DEBUG
        self.view.backgroundColor = color
#else
        Snapshot().show(at: self.view)
#endif
    }
}
