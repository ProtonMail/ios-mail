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

@preconcurrency import Combine
import InboxComposer
import InboxCore
import InboxCoreUI
import proton_app_uniffi
import SwiftUI
import TestableShareExtension
import UIKit

final class ShareViewController: UINavigationController {
    private static let mailUserSessionFactory = MailUserSessionFactory(apiConfig: .init(envId: .current))
    private let toastStateStore = ToastStateStore(initialState: .initial)

    private var alert: UIAlertController? {
        didSet {
            if oldValue == presentedViewController {
                dismiss(animated: false)
            }

            if let alert {
                present(alert, animated: true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setNavigationBarHidden(true, animated: false)

        guard let extensionContext else {
            fatalError()
        }

        Task { @MainActor in
            do {
                let userSession = try await Self.mailUserSessionFactory.make()

                let composerScreen = try await ComposerScreenFactory.makeComposer(
                    extensionContext: extensionContext,
                    userSession: userSession
                ) { [weak self] in self?.onDismiss(reason: $0) }
                .environmentObject(toastStateStore)

                setRootView(composerScreen)

                let result = await awaitSendingResult(userSession: userSession)

                switch result {
                case .success:
                    alert = .init(title: "Message sent!", message: nil, preferredStyle: .alert)
                    try? await Task.sleep(for: .seconds(2))
                    dismissShareExtension(error: nil)
                case .failure(let error):
                    onError(error)
                }
            } catch {
                onError(error)
            }
        }
    }

    private func onDismiss(reason: ComposerDismissReason) {
        switch reason {
        case .dismissedManually, .draftDiscarded:
            cancelSharing()
        case .messageScheduled, .messageSent:
            alert = .init(title: "Sending message...", message: nil, preferredStyle: .alert)
        }
    }

    private func cancelSharing() {
        AppLogger.log(message: "Sharing cancelled", category: .shareExtension)

        let cancelledError = NSError(domain: Bundle.main.bundleIdentifier!, code: NSUserCancelledError)
        dismissShareExtension(error: cancelledError)
    }

    private func awaitSendingResult(userSession: MailUserSession) async -> Result<Void, Error> {
        let sendResultPublisher = SendResultPublisher(userSession: userSession)

        var iterator = sendResultPublisher.results.values.compactMap { sendResultInfo -> Result<Void, Error>? in
            switch sendResultInfo.type {
            case .scheduling, .sending: nil
            case .scheduled, .sent: .success(())
            case .error(let error): .failure(error)
            }
        }
        .makeAsyncIterator()

        return await iterator.next()!
    }

    private func dismissShareExtension(error: Error?) {
        if let error {
            extensionContext?.cancelRequest(withError: error)
        } else {
            extensionContext?.completeRequest(returningItems: nil) { expired in
                if expired {
                    AppLogger.log(message: "Sharing interrupted", category: .shareExtension, isError: true)
                } else {
                    AppLogger.log(message: "Sharing completed", category: .shareExtension)
                }
            }
        }
    }

    private func onError(_ error: Error) {
        AppLogger.log(error: error, category: .shareExtension)

        let errorView = ErrorView(
            error: error,
            dismissExtension: { [unowned self] in
                self.dismissShareExtension(error: error)
            },
            launchMainApp: { [unowned self] in
                await self.application()?.open(URL(string: "\(Bundle.URLScheme.protonmail):")!)
            }
        )

        setRootView(errorView)
    }

    private func setRootView<Content: View>(_ rootView: Content) {
        let hostingController = UIHostingController(rootView: rootView)
        setViewControllers([hostingController], animated: false)
    }
}

private extension ApiEnvId {
    static var current: Self {
        #if QA
            if let dynamicDomain = UserDefaults.appGroup.string(forKey: "DYNAMIC_DOMAIN") {
                return .custom(dynamicDomain)
            }
        #endif

        return .prod
    }
}
