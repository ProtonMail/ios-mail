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

@testable import ProtonMail
import Combine
import InboxTesting
import proton_app_uniffi
import XCTest

final class MessageBodyStateStoreTests: XCTestCase {
    var sut: MessageBodyStateStore!
    var stubbedResult: GetMessageBodyResult!
    
    override func setUp() {
        super.setUp()
        sut = .init(
            messageID: .init(value: 1),
            mailbox: .dummy,
            bodyWrapper: .init(messageBody: { _, _ in self.stubbedResult })
        )
    }
    
    override func tearDown() {
        super.tearDown()
        sut = nil
        stubbedResult = nil
    }

    @MainActor
    func testState_WhenOnLoadAndSucceeds_ItReturnsLoaded() async {
        stubbedResult = .ok(DecryptedMessageStub(noPointer: .init()))
        
        XCTAssertEqual(sut.state.expectationState, .fetching)

        await sut.handle(action: .onLoad)

        XCTAssertEqual(sut.state.expectationState, .loaded(.init(
            banners: [],
            html: .init(rawBody: "<html>dummy</html>")
        )))
    }
    
    @MainActor
    func testState_WhenOnLoadAndFailedDueToNetworkError_ItReturnsNoConnectionError() async {
        stubbedResult = .error(.other(.network))
        
        await sut.handle(action: .onLoad)
        
        XCTAssertEqual(sut.state.expectationState, .noConnection)
    }
    
    @MainActor
    func testState_WhenOnLoadAndFailedDueToOtherReasonError_ItReturnsError() async {
        stubbedResult = .error(.other(.otherReason(.other("An error occurred"))))
        
        await sut.handle(action: .onLoad)
        
        XCTAssertEqual(sut.state.expectationState, .error)
    }
}

private extension MessageBodyState {
    
    var expectationState: ExpectationMessageBodyState {
        switch self {
        case .fetching:
            return .fetching
        case .loaded(let body):
            return .loaded(.init(banners: body.banners, html: .init(rawBody: body.html.rawBody)))
        case .error:
            return .error
        case .noConnection:
            return .noConnection
        }
    }
    
}

private enum ExpectationMessageBodyState: Equatable {
    struct MessageBody: Equatable {
        struct HTML: Equatable {
            let rawBody: String
        }
        
        let banners: [MessageBanner]
        let html: HTML
    }
    
    case fetching
    case loaded(MessageBody)
    case error
    case noConnection
}

private final class DecryptedMessageStub: DecryptedMessage, @unchecked Sendable {

    override func bodyWithDefaults() async -> BodyOutput {
        .init(
            body: "<html>dummy</html>",
            hadBlockquote: true,
            tagsStripped: 0,
            utmStripped: 0,
            remoteImagesDisabled: 0,
            embeddedImagesDisabled: 0,
            transformOpts: .init(
                showBlockQuote: false,
                hideRemoteImages: .none,
                hideEmbeddedImages: .none
            ),
            bodyBanners: []
        )
    }

}
