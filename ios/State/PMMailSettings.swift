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
import proton_mail_uniffi

protocol PMMailSettingsProtocol {
    var viewModeHasChanged: AnyPublisher<Void, Never> { get }
}

final class PMMailSettings: ObservableObject, PMMailSettingsProtocol, @unchecked Sendable {
    @Published private(set) var settings: MailSettings

    var viewModeHasChanged: AnyPublisher<Void, Never> {
        _viewModeHasChanged.eraseToAnyPublisher()
    }

    private let _viewModeHasChanged: PassthroughSubject<Void, Never> = .init()
    private var mailUserSettings: MailUserSettings

    init(userSession: MailUserSession) {
        AppLogger.log(message: "PMMailSettings init")
        let mailUserSettings = MailUserSettings(session: userSession, callback: nil)
        self.mailUserSettings = mailUserSettings
        do {
            self.settings = try mailUserSettings.value()
        } catch {
            AppLogger.log(error: error)
            self.settings = MailSettings.defaults()
        }
        // hack: init again to set callback
        self.mailUserSettings = MailUserSettings(session: userSession, callback: PMMailSettingsUpdated(delegate: self))
    }

    @MainActor
    private func updateSettings() {
        do {
            let previousViewMode = settings.viewMode
            settings = try mailUserSettings.value()
            if previousViewMode != settings.viewMode {
                _viewModeHasChanged.send()
            }
        } catch {
            AppLogger.log(error: error)
        }
    }

    deinit {
        AppLogger.log(message: "PMMailSettings deinit")
    }
}

extension PMMailSettings: MailSettingsUpdated {
    func onUpdated() {
        Task {
            await updateSettings()
        }
    }
}

struct EmptyPMMailSettings: PMMailSettingsProtocol {
    var viewModeHasChanged: AnyPublisher<Void, Never> {
        _viewModeHasChanged.eraseToAnyPublisher()
    }
    var _viewModeHasChanged: PassthroughSubject<Void, Never> = .init()
}

extension MailSettings {

    /// These defaults are wrong and only a wrokaround until Rust provides default values
    static func defaults() -> MailSettings {
        .init(displayName: "", signature: "", theme: "", autoSaveContacts: false, composerMode: .maximized, messageButtons: .readFirst, showImages: .autoLoadBoth, showMoved: .doNotKeep, autoDeleteSpamAndTrashDays: nil, almostAllMail: .allMail, nextMessageOnMove: nil, viewMode: .conversations, viewLayout: .column, swipeLeft: .archive, swipeRight: .archive, shortcuts: false, pmSignature: .disabled, pmSignatureReferralLink: false, imageProxy: 0, numMessagePerPage: 0, draftMimeType: "", receiveMimeType: "", showMimeType: "", enableFolderColor: false, inheritParentFolderColor: false, submissionAccess: false, rightToLeft: .leftToRight, attachPublicKey: false, sign: false, pgpScheme: .inline, promptPin: false, stickyLabels: false, confirmLink: false, delaySendSeconds: 0, fontFace: nil, spamAction: nil, blockSenderConfirmation: nil, mobileSettings: nil, hideRemoteImages: false, hideSenderImages: false)
    }
}
