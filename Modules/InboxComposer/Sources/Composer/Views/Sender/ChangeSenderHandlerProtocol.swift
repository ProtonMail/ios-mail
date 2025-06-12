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

import proton_app_uniffi

protocol ChangeSenderHandlerProtocol {
    func listSenderAddresses() async throws -> DraftSenderAddressList

    @MainActor
    func changeSenderAddress(email: String) async throws
}

struct MockChangeSenderHandler: ChangeSenderHandlerProtocol {
    func listSenderAddresses() async throws -> DraftSenderAddressList {
        .init(
            available: [
                "norbert.e@pm.me",
                "norbert.eric@pm.me",
                "e.norbert@protonmail.me",
            ],
            active: "norbert.eric@pm.me"
        )
    }

    @MainActor
    func changeSenderAddress(email: String) async throws {}
}
