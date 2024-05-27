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

struct ConversationScreen: View {
    @State var conversation: ConversationSeed
    init(conversation: ConversationSeed) {
        self.conversation = conversation
    }

    var body: some View {
        VStack {
            Text(conversation.subject)
                .font(.headline)
            Text(conversation.senders)
                .font(.callout)
        }
    }
}

struct ConversationSeed {
    let id: PMLocalConversationId
    let subject: String
    let senders: String
}

final class ConversationModel: ObservableObject {
    private let dependencies: Dependencies

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies

        
    }
}

extension ConversationModel {

    struct Dependencies {
        let appContext: AppContext

        init(appContext: AppContext = .shared) {
            self.appContext = appContext
        }
    }
}
