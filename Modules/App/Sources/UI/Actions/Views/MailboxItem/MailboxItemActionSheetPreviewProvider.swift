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

import proton_app_uniffi

enum MailboxItemActionSheetPreviewProvider {
    static func actionsProvider() -> ActionsProvider {
        ActionsProvider(
            message: { _, themeOpts, _ in
                var generalActions: [GeneralActions] = [
                    .saveAsPdf,
                    .print,
                    .viewHeaders,
                    .viewHtml,
                    .reportPhishing,
                ]

                // this logic attempts to mimic what the SDK does for previewing and testing purposes
                // if we could use `actionsProvider: .productionInstance` in those cases, we wouldn't need this
                if themeOpts.currentTheme == .darkMode {
                    if themeOpts.themeOverride == .lightMode {
                        generalActions.append(.viewMessageInDarkMode)
                    } else {
                        generalActions.append(.viewMessageInLightMode)
                    }
                }

                return .ok(
                    .init(
                        replyActions: [.reply, .forward, .replyAll],
                        messageActions: [.markUnread, .star, .pin, .labelAs],
                        moveActions: [
                            .moveToSystemFolder(.init(localId: .init(value: 1), name: .inbox)),
                            .moveToSystemFolder(.init(localId: .init(value: 2), name: .archive)),
                            .moveToSystemFolder(.init(localId: .init(value: 3), name: .spam)),
                            .moveToSystemFolder(.init(localId: .init(value: 4), name: .trash)),
                            .moveTo,
                        ],
                        generalActions: generalActions
                    ))
            },
            conversation: { _, _ in
                .ok(
                    .init(
                        conversationActions: [],
                        moveActions: [],
                        generalActions: []
                    ))
            }
        )
    }
}
