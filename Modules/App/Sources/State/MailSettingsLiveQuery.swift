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
import Foundation
import InboxCore
import proton_app_uniffi

@MainActor
protocol MailSettingLiveQuerying {
    /// Emits an event only when the user's view mode setting changes
    var viewModeHasChanged: AnyPublisher<Void, Never> { get }

    func settingHasChanged<Property: Equatable>(keyPath: KeyPath<MailSettings, Property>) -> AnyPublisher<Property, Never>
}

final class MailSettingsLiveQuery: MailSettingLiveQuerying {

    private let userSession: MailUserSession
    private var watchHandle: WatchHandle?
    private let settingsSubject: CurrentValueSubject<MailSettings, Never> = .init(.defaults())

    private lazy var updateCallback = LiveQueryCallbackWrapper { [weak self] in
        self?.onSettingsUpdate()
    }

    init(userSession: MailUserSession) {
        self.userSession = userSession
        setUpLiveQuery()
    }

    deinit {
        watchHandle?.disconnect()
    }

    // MARK: - MailSettingLiveQuerying

    var viewModeHasChanged: AnyPublisher<Void, Never> {
        settingHasChanged(keyPath: \.viewMode)
            .map { _ in }
            .eraseToAnyPublisher()
    }

    func settingHasChanged<Property: Equatable>(keyPath: KeyPath<MailSettings, Property>) -> AnyPublisher<Property, Never> {
        settingsSubject
            .map(keyPath)
            .removeDuplicates()
            .dropFirst()
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func setUpLiveQuery() {
        Task {
            switch await watchMailSettings(ctx: userSession, callback: updateCallback) {
            case .ok(let settingsWatcher):
                self.watchHandle = settingsWatcher.watchHandle
                settingsSubject.value = settingsWatcher.settings
            case .error(let error):
                AppLogger.log(error: error)
            }
        }
    }

    nonisolated private func onSettingsUpdate() {
        Task { @MainActor in
            settingsSubject.value = try await mailSettings(ctx: userSession).get()
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
            pmSignature: .init(value: 1),
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
