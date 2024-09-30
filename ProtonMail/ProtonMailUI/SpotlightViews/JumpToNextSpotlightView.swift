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

import SwiftUI

public struct JumpToNextSpotlightView: View {
    public let config = HostingProvider()
    let buttonTitle: String
    let message: String
    let title: String
    var closeAction: ((UIViewController?, Bool) -> Void)?

    public init(
        buttonTitle: String,
        message: String,
        title: String,
        closeAction: ((UIViewController?, Bool) -> Void)? = nil
    ) {
        self.buttonTitle = buttonTitle
        self.message = message
        self.title = title
        self.closeAction = closeAction
    }

    public var body: some View {
        SheetLikeSpotlightView(
            config: config,
            buttonTitle: buttonTitle,
            closeAction: closeAction,
            message: message,
            spotlightImage: .jumpToNextSpotlight,
            title: title,
            imageAlignBottom: true
        )
    }
}

#Preview {
    JumpToNextSpotlightView(
        buttonTitle: "Turn on feature",
        message: "View the next email in your inbox when you delete or move the current email. ",
        title: "Read emails faster"
    )
}
