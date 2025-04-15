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

import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct MessageBodyHTMLView: View {
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.openURL) var urlOpener
    @State var bodyContentHeight: CGFloat = 0.0

    let messageBody: MessageBodyState.Body
    let htmlLoaded: () -> Void
    
    /// This value is key to the conversation scrolling to the opened message. We don't
    /// know the height of the body before it has finished rendering in the webview, having a
    /// meaningful default size avoids more than one scroll movement (before and after the html rendering).
    private var loadingHtmlInitialHeight: CGFloat {
        mainWindowSize.height * 0.5
    }

    var body: some View {
        switch messageBody {
        case .fetching:
            ProgressView()
                .padding(.vertical, DS.Spacing.jumbo)
        case .loaded(let body):
            bodyReaderView(with: body.html)
        case .error(let error):
            Text(String(describing: error))
        case .noConnection:
            NoConnectionView()
        }
    }

    private func bodyReaderView(with body: MessageBody.HTML) -> some View {
        ZStack {
            ProtonSpinner()
                .frame(height: bodyContentHeight > 0 ? bodyContentHeight : loadingHtmlInitialHeight)
                .removeViewIf(bodyContentHeight > 0)
            MessageBodyReaderView(
                bodyContentHeight: $bodyContentHeight,
                body: body,
                urlOpener: urlOpener,
                htmlLoaded: htmlLoaded
            )
            .frame(height: bodyContentHeight)
            .padding([.vertical, .horizontal], DS.Spacing.large)
            .opacity(bodyContentHeight > 0 ? 1 : 0)
            .accessibilityIdentifier(MessageBodyViewIdentifiers.messageBody)
        }
    }
}

private struct MessageBodyViewIdentifiers {
    static let messageBody = "detail.messageBody"
}
