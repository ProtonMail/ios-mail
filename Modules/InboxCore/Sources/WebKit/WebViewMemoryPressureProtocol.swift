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
import WebKit

public protocol WebViewMemoryPressureProtocol: AnyObject {
    func contentReload(_ contentReload: @escaping () -> Void)
    func markWebContentProcessTerminated()
}

public final class WebViewMemoryPressureHandler: WebViewMemoryPressureProtocol {
    private let loggerCategory: AppLogger.Category
    private var contentReload: (() -> Void)?
    private var pendingContentReload: Bool = false
    private var cancellables = Set<AnyCancellable>()

    public init(loggerCategory: AppLogger.Category, notificationCenter: NotificationCenter = .default) {
        self.loggerCategory = loggerCategory
        notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.appWillEnterForeground() }
            .store(in: &cancellables)
    }

    public func contentReload(_ contentReload: @escaping () -> Void) {
        self.contentReload = contentReload
    }

    public func markWebContentProcessTerminated() {
        AppLogger.log(message: "web content process did terminate", category: loggerCategory)
        self.pendingContentReload = true
    }

    private func appWillEnterForeground() {
        guard pendingContentReload else { return }
        AppLogger.log(message: "web content reload after process termination", category: loggerCategory)
        contentReload?()
        pendingContentReload = false
    }
}
