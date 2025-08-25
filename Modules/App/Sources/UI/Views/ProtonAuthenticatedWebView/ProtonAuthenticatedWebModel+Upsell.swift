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

import InboxCore
import InboxIAP
import WebKit

extension ProtonAuthenticatedWebModel {
    func setupUpsellScreenCapability(in userContentController: WKUserContentController) {
        userContentController.add(self, name: "upsell")
        userContentController.addUserScript(.overrideUpsellModalPresentation)
    }
}

extension ProtonAuthenticatedWebModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let upsellCoordinator, let entryPoint = entryPoint(from: message.body) else {
            return
        }

        Task {
            do {
                presentedUpsell = try await upsellCoordinator.presentUpsellScreen(entryPoint: entryPoint)
            } catch {
                AppLogger.log(error: error, category: .payments)
            }
        }
    }

    private func entryPoint(from messageBody: Any) -> UpsellScreenEntryPoint? {
        switch messageBody as? String {
        case "folders-action":
            return .folders
        case "labels-action":
            return .labels
        default:
            return nil
        }
    }
}

private extension WKUserScript {
    static let overrideUpsellModalPresentation: WKUserScript = {
        let url = Bundle.main.url(forResource: "OverrideUpsellButtonInWebView", withExtension: "js")!
        let source = try! String(contentsOf: url, encoding: .utf8)
        return .init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }()
}
