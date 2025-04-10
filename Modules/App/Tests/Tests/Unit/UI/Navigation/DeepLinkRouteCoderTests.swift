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

import Testing

@testable import ProtonMail

struct DeepLinkRouteCoderTests {
    private let sut = DeepLinkRouteCoder.self

    private let testSeed = MailboxMessageSeed(remoteId: .init(value: "foo123=="), subject: "foo bar 😀")
    private let testURL = URL(string: "protonmail://messages/foo123==?subject=foo%20bar%20%F0%9F%98%80")!

    @Test
    func encoding_openMessageRoute() async throws {
        let deepLink = try #require(sut.encode(route: .mailboxOpenMessage(seed: testSeed)))
        #expect(deepLink == testURL)
    }

    @Test
    func decoding_openMessageRoute() async throws {
        let route: Route = try #require(sut.decode(deepLink: testURL))
        #expect(route == .mailboxOpenMessage(seed: testSeed))
    }
}
