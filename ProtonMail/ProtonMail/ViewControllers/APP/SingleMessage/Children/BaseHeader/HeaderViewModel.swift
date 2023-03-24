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

import Foundation
import UIKit

class HeaderViewModel {
    var reloadView: (() -> Void)?

    private(set) var infoProvider: MessageInfoProvider {
        didSet { reloadView?() }
    }

    var isOfficialBadgeHidden: Bool {
        do {
            let sender = try infoProvider.message.parseSender()
            return !sender.isFromProton
        } catch {
            assertionFailure("\(error)")
            return true
        }
    }

    init(infoProvider: MessageInfoProvider) {
        self.infoProvider = infoProvider
    }

    func providerHasChanged(provider: MessageInfoProvider) {
        infoProvider = provider
    }

    func fetchSenderImageIfNeeded(
        isDarkMode: Bool,
        scale: CGFloat,
        completion: @escaping (UIImage?) -> Void
    ) {
        infoProvider.fetchSenderImageIfNeeded(
            isDarkMode: isDarkMode,
            scale: scale,
            completion: completion
        )
    }
}
