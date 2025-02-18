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

import Combine
import proton_app_uniffi

protocol MailSettingLiveQuerying {
    /// Emits an event only when the user's view mode setting changes
    var viewModeHasChanged: AnyPublisher<Void, Never> { get }
}

final class MailSettingsLiveQuery: @unchecked Sendable, MailSettingLiveQuerying {

    private let userSession: MailUserSession
    private var watchHandle: WatchHandle?
    private let settingsSubject: CurrentValueSubject<MailSettings, Never> = .init(.defaults())
    private let updateCallback = LiveQueryCallbackWrapper()

    init(userSession: MailUserSession) {
        self.userSession = userSession
        setUpLiveQuery()
    }

    deinit {
        watchHandle?.disconnect()
    }

    // MARK: - MailSettingLiveQuerying

    var settingsPublisher: AnyPublisher<MailSettings, Never> {
        settingsSubject.eraseToAnyPublisher()
    }

    var viewModeHasChanged: AnyPublisher<Void, Never> {
        settingsPublisher
            .map(\.viewMode)
            .removeDuplicates()
            .dropFirst()
            .map { _ in }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func setUpLiveQuery() {
        updateCallback.delegate = { [weak self] in
            self?.onSettingsUpdate()
        }

        Task {
            switch await watchMailSettings(ctx: userSession, callback: updateCallback) {
            case .ok(let settingsWatcher):
                self.watchHandle = settingsWatcher.watchHandle
                settingsSubject.value = settingsWatcher.settings
            case .error(let error):
                break
            }
        }
    }

    private func onSettingsUpdate() {
        Task {
            settingsSubject.value = await mailSettings(ctx: userSession)
        }
    }
}

extension MailSettings {

    /// These defaults are wrong and only a wrokaround until Rust provides default values
    static func defaults() -> MailSettings {
        .init(
            almostAllMail: .allMail,
            attachPublicKey: false,
            autoDeleteSpamAndTrashDays: nil,
            autoSaveContacts: false,
            blockSenderConfirmation: nil,
            composerMode: .normal,
            confirmLink: false,
            delaySendSeconds: .max,
            displayName: "",
            draftMimeType: .applicationJson,
            enableFolderColor: false,
            fontFace: nil,
            hideRemoteImages: false, 
            hideEmbeddedImages: false,
            hideSenderImages: false,
            imageProxy: .max,
            inheritParentFolderColor: false,
            messageButtons: .readFirst,
            mobileSettings: nil,
            nextMessageOnMove: nil,
            numMessagePerPage: .max,
            pgpScheme: .inline,
            pmSignature: .enabled,
            pmSignatureReferralLink: false,
            promptPin: false,
            receiveMimeType: .applicationJson,
            rightToLeft: .leftToRight,
            shortcuts: false,
            showImages: .autoLoadBoth,
            showMimeType: .applicationJson,
            showMoved: .doNotKeep,
            sign: false,
            signature: "",
            spamAction: nil,
            stickyLabels: false,
            submissionAccess: false,
            swipeLeft: .archive,
            swipeRight: .archive,
            theme: "",
            viewLayout: .column,
            viewMode: .conversations
        )
    }
}
