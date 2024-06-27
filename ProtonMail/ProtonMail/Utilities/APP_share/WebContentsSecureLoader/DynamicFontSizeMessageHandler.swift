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

@preconcurrency import WebKit

final class DynamicFontSizeMessageHandler: NSObject, WKScriptMessageHandlerWithReply {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage,
        replyHandler: @escaping (Any?, String?) -> Void
    ) {
        switch message.name {
        case "scaledValue":
            if let originalValue = message.body as? CGFloat {
                let scaledValue = UIFontMetrics.default.scaledValue(for: originalValue)
                replyHandler(scaledValue, nil)
            } else {
                assertionFailure("Unexpected body: \(message.body)")
                replyHandler(nil, nil)
            }
        default:
            assertionFailure("Unexpected message: \(message.name)")
            replyHandler(nil, nil)
        }
    }
}
