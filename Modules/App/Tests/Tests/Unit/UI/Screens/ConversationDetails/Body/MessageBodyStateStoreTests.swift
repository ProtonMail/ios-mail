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
import InboxTesting
import proton_app_uniffi
import Testing

@MainActor
final class MessageBodyStateStoreTests {
    var sut: MessageBodyStateStore!
    var stubbedResult: GetMessageBodyResult!
    
    init() {
        sut = .init(
            messageID: .init(value: 1),
            mailbox: .dummy,
            bodyWrapper: .init(messageBody: { [unowned self] _, _ in await self.stubbedResult })
        )
    }

    @Test
    func testState_WhenOnLoadAndSucceedsFetchingBodyWithDefaultOptions_ItReturnsLoadedWithCorrectMessageBody() async {
        let decryptedMessageSpy = DecryptedMessageSpy(noPointer: .init())
        
        stubbedResult = .ok(decryptedMessageSpy)
        
        #expect(decryptedMessageSpy.bodyWithDefaultsCalls == 0)
        #expect(sut.state.expectationState == .fetching)

        await sut.handle(action: .onLoad)

        #expect(decryptedMessageSpy.bodyWithDefaultsCalls == 1)
        #expect(sut.state.expectationState == .loaded(.init(
            banners: [],
            html: .init(rawBody: "<html>dummy</html>")
        )))
    }
    
    @Test
    func testState_WhenOnLoadAndFailedDueToNetworkError_ItReturnsNoConnectionError() async {
        stubbedResult = .error(.other(.network))
        
        await sut.handle(action: .onLoad)
        
        #expect(sut.state.expectationState == .noConnection)
    }
    
    @Test
    func testState_WhenOnLoadAndFailedDueToOtherReasonError_ItReturnsError() async {
        stubbedResult = .error(.other(.otherReason(.other("An error occurred"))))
        
        await sut.handle(action: .onLoad)
        
        #expect(sut.state.expectationState == .error)
    }
}

private extension MessageBodyState {
    
    var expectationState: ExpectationMessageBodyState {
        switch self {
        case .fetching:
            return .fetching
        case .loaded(let body):
            let messageBody = ExpectationMessageBodyState.MessageBody(
                banners: body.banners,
                html: .init(rawBody: body.html.rawBody)
            )
            return .loaded(messageBody)
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

private final class DecryptedMessageSpy: DecryptedMessage, @unchecked Sendable {
    
    let defaultOptions: TransformOpts = .init(
        showBlockQuote: true,
        hideRemoteImages: .none,
        hideEmbeddedImages: .none
    )
    
    private(set) var bodyWithDefaultsCalls: Int = 0

    override func bodyWithDefaults() async -> BodyOutput {
        bodyWithDefaultsCalls += 1
        
        return .init(
            body: "<html>dummy</html>",
            hadBlockquote: true,
            tagsStripped: 0,
            utmStripped: 0,
            remoteImagesDisabled: 0,
            embeddedImagesDisabled: 0,
            transformOpts: defaultOptions,
            bodyBanners: []
        )
    }

}
