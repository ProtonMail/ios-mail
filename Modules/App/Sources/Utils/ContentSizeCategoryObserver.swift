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

import Combine
import UIKit

@MainActor
@Observable
final class ContentSizeCategoryObserver {
    private(set) var contentSizeCategory: UIContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter
            .default
            .publisher(for: UIContentSizeCategory.didChangeNotification)
            .compactMap { notification in
                notification.userInfo?[UIContentSizeCategory.newValueUserInfoKey] as? UIContentSizeCategory
            }
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [unowned self] newCategory in
                contentSizeCategory = newCategory
            }
            .store(in: &cancellables)
    }
}
