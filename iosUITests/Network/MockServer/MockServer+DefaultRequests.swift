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

import Foundation

extension MockServer {
    func addRequestsWithDefaults(
        useDefaultLabels: Bool = true,
        useDefaultConversationCount: Bool = true,
        useDefaultMessagesCount: Bool = true,
        useDefaultEventsLatest: Bool = true,
        useDefaultMailSettings: Bool = true,
        useDefaultCoreSettings: Bool = true,
        _ additionalRequests: NetworkRequest...
    ) async {
        if useDefaultLabels {
            await addRequests(
                NetworkRequest(
                    method: .get,
                    remotePath: "/core/v4/labels?Type=1",
                    localPath: "labels-type1_base_placeholder.json",
                    serveOnce: true
                ),
                NetworkRequest(
                    method: .get,
                    remotePath: "/core/v4/labels?Type=2",
                    localPath: "labels-type2_base_placeholder.json",
                    serveOnce: true
                ),
                NetworkRequest(
                    method: .get,
                    remotePath: "/core/v4/labels?Type=3",
                    localPath: "labels-type3_base_placeholder.json",
                    serveOnce: true
                ),
                NetworkRequest(
                    method: .get,
                    remotePath: "/core/v4/labels?Type=4",
                    localPath: "labels-type4_base_placeholder.json",
                    serveOnce: true
                )
            )

            if useDefaultConversationCount {
                await addRequests(
                    NetworkRequest(
                        method: .get,
                        remotePath: "/mail/v4/conversations/count",
                        localPath: "conversations-count_base_placeholder.json",
                        serveOnce: true
                    )
                )
            }

            if useDefaultMessagesCount {
                await addRequests(
                    NetworkRequest(
                        method: .get,
                        remotePath: "/mail/v4/messages/count",
                        localPath: "messages-count_base_placeholder.json",
                        serveOnce: true
                    )
                )
            }

            if useDefaultEventsLatest {
                await addRequests(
                    NetworkRequest(
                        method: .get,
                        remotePath: "/core/v4/events/latest",
                        localPath: "events-latest_base_placeholder.json",
                        serveOnce: true
                    )
                )
            }

            if useDefaultCoreSettings {
                await addRequests(
                    NetworkRequest(
                        method: .get,
                        remotePath: "/core/v4/settings",
                        localPath: "core-v4-settings_base_placeholder.json",
                        serveOnce: true
                    )
                )
            }

            if useDefaultMailSettings {
                await addRequests(
                    NetworkRequest(
                        method: .get,
                        remotePath: "/mail/v4/settings",
                        localPath: "mail-v4-settings_placeholder_conversation.json",
                        serveOnce: true
                    )
                )
            }
        }

        for additionalRequest in additionalRequests {
            await addRequests(additionalRequest)
        }
    }
}
