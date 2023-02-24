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

final class DownloadedMessagesViewModel: DownloadedMessagesViewModelProtocol {
    var input: DownloadedMessagesViewModelInput { self }
    var output: DownloadedMessagesViewModelOutput { self }
    private weak var uiDelegate: DownloadedMessagesUIProtocol?
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension DownloadedMessagesViewModel: DownloadedMessagesViewModelInput {
    func viewWillAppear() {
        // TODO: use the dependencies
    }

    func didChangeStorageLimitValue(newValue: ByteCount) {
        // TODO: use the dependencies
    }

    func didTapClearStorageUsed() {
        // TODO: use the dependencies
    }
}

extension DownloadedMessagesViewModel: DownloadedMessagesViewModelOutput {
    var sections: [DownloadedMessagesSection] {
        [.messageHistory, .storageLimit, .localStorageUsed]
    }

    var storageLimitSelected: ByteCount {
        // TODO: use the dependencies
        return 600_000_000
    }

    var localStorageUsed: ByteCount {
        // TODO: use the dependencies
        return 150_000_000
    }

    func setUIDelegate(_ delegate: DownloadedMessagesUIProtocol) {
        self.uiDelegate = delegate
    }
}

extension DownloadedMessagesViewModel {

    struct Dependencies {
        // TODO: Add dependencies
    }
}
