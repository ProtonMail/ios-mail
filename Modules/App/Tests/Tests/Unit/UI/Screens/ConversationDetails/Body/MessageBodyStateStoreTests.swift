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
@testable import InboxCoreUI
import InboxTesting
import proton_app_uniffi
import Testing

final class MessageBodyStateStoreTests {
    var sut: MessageBodyStateStore!
    var stubbedMessageID: ID!
    var stubbedMessageBodyResult: GetMessageBodyResult!
    var markAsNotSpamMessageIDs: [ID]!
    var stubbedMarkAsNotSpamResult: VoidActionResult!
    var toastStateStore: ToastStateStore!
    
    init() {
        stubbedMessageID = .init(value: 42)
        markAsNotSpamMessageIDs = []
        toastStateStore = .init(initialState: .initial)
        sut = .init(
            messageID: stubbedMessageID,
            mailbox: .dummy,
            bodyWrapper: .init(messageBody: { [unowned self] _, _ in self.stubbedMessageBodyResult }),
            actionsWrapper: .init(
                markMessageHam: { @MainActor [unowned self] _, messageID in
                    self.markAsNotSpamMessageIDs.append(messageID)
                    return stubbedMarkAsNotSpamResult
                }
            ),
            toastStateStore: toastStateStore
        )
    }
    
    deinit {
        toastStateStore = nil
        stubbedMarkAsNotSpamResult = nil
        markAsNotSpamMessageIDs = nil
        stubbedMessageID = nil
        stubbedMessageBodyResult = nil
        sut = nil
    }
    
    // MARK: - `onLoad` action

    @Test
    func testState_WhenOnLoadAndSucceedsFetchingBodyWithDefaultOptions_ItReturnsLoadedWithCorrectMessageBody() async {
        let initialOptions = TransformOpts(
            showBlockQuote: true,
            hideRemoteImages: .none,
            hideEmbeddedImages: .none
        )
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)
        
        stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        
        #expect(decryptedMessageSpy.bodyWithDefaultsCalls == 0)
        #expect(sut.state == .fetching)

        await sut.handle(action: .onLoad)

        #expect(decryptedMessageSpy.bodyWithDefaultsCalls == 1)
        #expect(sut.state == .loaded(.init(
            banners: [],
            html: .init(
                rawBody: "<html>dummy</html>",
                options: initialOptions,
                embeddedImageProvider: decryptedMessageSpy
            )
        )))
    }
    
    @Test
    func testState_WhenOnLoadAndFailedDueToNetworkError_ItReturnsNoConnectionError() async {
        stubbedMessageBodyResult = .error(.other(.network))
        
        await sut.handle(action: .onLoad)
        
        #expect(sut.state == .noConnection)
    }
    
    @Test
    func testState_WhenOnLoadAndFailedDueToOtherReasonError_ItReturnsError() async {
        let expectedError: ActionError = .other(.otherReason(.other("An error occurred")))
        
        stubbedMessageBodyResult = .error(expectedError)
        
        await sut.handle(action: .onLoad)
        
        #expect(sut.state == .error(expectedError))
    }
    
    // MARK: - `displayEmbeddedImagesTapped` action
    
    @Test
    func testState_WhenDisplayEmbeddedImagesActionTriggered_ItFetchesBodyWithModifiedOptions() async {
        let initialOptions = TransformOpts(
            showBlockQuote: true,
            hideRemoteImages: .none,
            hideEmbeddedImages: .none
        )
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)
        
        stubbedMessageBodyResult = .ok(decryptedMessageSpy)

        await sut.handle(action: .onLoad)
        
        #expect(decryptedMessageSpy.bodyWithDefaultsCalls == 1)
        #expect(sut.state == .loaded(.init(
            banners: [],
            html: .init(
                rawBody: "<html>dummy</html>",
                options: initialOptions,
                embeddedImageProvider: decryptedMessageSpy
            )
        )))
        
        await sut.handle(action: .displayEmbeddedImages)
        
        let updatedOptions = initialOptions.copy(\.hideEmbeddedImages, to: false)
        
        #expect(decryptedMessageSpy.bodyWithDefaultsCalls == 1)
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [updatedOptions])
        #expect(sut.state == .loaded(.init(
            banners: [],
            html: .init(
                rawBody: "<html>dummy_with_custom_options</html>",
                options: updatedOptions,
                embeddedImageProvider: decryptedMessageSpy
            )
        )))
    }
    
    // MARK: - `downloadRemoteContentTapped` action
    
    @Test
    func testState_WhenDownloadRemoteContentActionTriggered_ItFetchesBodyWithModifiedOptions() async {
        let initialOptions = TransformOpts(
            showBlockQuote: true,
            hideRemoteImages: .none,
            hideEmbeddedImages: .none
        )
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)
        
        stubbedMessageBodyResult = .ok(decryptedMessageSpy)

        await sut.handle(action: .onLoad)
        
        #expect(decryptedMessageSpy.bodyWithDefaultsCalls == 1)
        #expect(sut.state == .loaded(.init(
            banners: [],
            html: .init(
                rawBody: "<html>dummy</html>",
                options: initialOptions,
                embeddedImageProvider: decryptedMessageSpy
            )
        )))
        
        await sut.handle(action: .downloadRemoteContent)
        
        let updatedOptions = initialOptions.copy(\.hideRemoteImages, to: false)
        
        #expect(decryptedMessageSpy.bodyWithDefaultsCalls == 1)
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [updatedOptions])
        #expect(sut.state == .loaded(.init(
            banners: [],
            html: .init(
                rawBody: "<html>dummy_with_custom_options</html>",
                options: updatedOptions,
                embeddedImageProvider: decryptedMessageSpy
            )
        )))
    }
    
    // MARK: - `markAsLegitimateSpam` action
    
    @Test
    func testState_WhenSpamMarkAsLegitimateActionSucceeds_ItMarksMessageAsNotSpamAndFetchesBodyWithLastOptions() async {
        let initialOptions = TransformOpts(
            showBlockQuote: true,
            hideRemoteImages: .none,
            hideEmbeddedImages: .none
        )
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)
        
        stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        stubbedMarkAsNotSpamResult = .ok

        await sut.handle(action: .onLoad)
        await sut.handle(action: .displayEmbeddedImages)
        
        let updatedOptions = initialOptions.copy(\.hideEmbeddedImages, to: false)
        
        #expect(decryptedMessageSpy.bodyWithDefaultsCalls == 1)
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [updatedOptions])
        #expect(sut.state == .loaded(.init(
            banners: [],
            html: .init(
                rawBody: "<html>dummy_with_custom_options</html>",
                options: updatedOptions,
                embeddedImageProvider: decryptedMessageSpy
            )
        )))
        
        await sut.handle(action: .spamMarkAsLegitimate)
        
        #expect(markAsNotSpamMessageIDs == [stubbedMessageID!])
        #expect(decryptedMessageSpy.bodyWithDefaultsCalls == 1)
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [updatedOptions, updatedOptions])
        #expect(sut.state == .loaded(.init(
            banners: [],
            html: .init(
                rawBody: "<html>dummy_with_custom_options</html>",
                options: updatedOptions,
                embeddedImageProvider: decryptedMessageSpy
            )
        )))
    }
    
    @Test
    func testState_WhenSpamMarkAsLegitimateActionFails_ItDoesNotFetchBodyAndPresentsErrorToast() async {
        let initialOptions = TransformOpts(
            showBlockQuote: true,
            hideRemoteImages: .none,
            hideEmbeddedImages: .none
        )
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)
        let expectedActionError: ActionError = .other(.network)
        
        stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        stubbedMarkAsNotSpamResult = .error(expectedActionError)

        await sut.handle(action: .onLoad)
        await sut.handle(action: .displayEmbeddedImages)
        
        let updatedOptions = initialOptions.copy(\.hideEmbeddedImages, to: false)
        
        #expect(decryptedMessageSpy.bodyWithDefaultsCalls == 1)
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [updatedOptions])
        #expect(sut.state == .loaded(.init(
            banners: [],
            html: .init(
                rawBody: "<html>dummy_with_custom_options</html>",
                options: updatedOptions,
                embeddedImageProvider: decryptedMessageSpy
            )
        )))
        
        await sut.handle(action: .spamMarkAsLegitimate)
        
        #expect(markAsNotSpamMessageIDs == [stubbedMessageID!])
        #expect(decryptedMessageSpy.bodyWithDefaultsCalls == 1)
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [updatedOptions])
        #expect(toastStateStore.state.toasts == [.error(message: expectedActionError.localizedDescription)])
    }
}

extension MessageBodyState: @retroactive Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.fetching, .fetching):
            return true
        case (.loaded(let lhsBody), .loaded(let rhsBody)):
            return lhsBody == rhsBody
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.noConnection, .noConnection):
            return true
        default:
            return false
        }
    }

}

extension MessageBody: @retroactive Equatable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        let areHTMLsEqual =
            lhs.html.rawBody == rhs.html.rawBody &&
            lhs.html.options == rhs.html.options &&
            lhs.html.embeddedImageProvider === rhs.html.embeddedImageProvider
        let areBannersEqual = lhs.banners == rhs.banners
        
        return areHTMLsEqual && areBannersEqual
    }
    
}

private final class DecryptedMessageSpy: DecryptedMessage, @unchecked Sendable {
    
    private let stubbedOptions: TransformOpts
    
    init(stubbedOptions: TransformOpts) {
        self.stubbedOptions = stubbedOptions
        super.init(noPointer: .init())
    }
    
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }
    
    private(set) var bodyWithDefaultsCalls: Int = 0
    private(set) var bodyWithOptionsCalls: [TransformOpts] = []
    
    // MARK: - DecryptedMessage

    override func bodyWithDefaults() async -> BodyOutput {
        bodyWithDefaultsCalls += 1
        
        return .init(
            body: "<html>dummy</html>",
            hadBlockquote: true,
            tagsStripped: 0,
            utmStripped: 0,
            remoteImagesDisabled: 0,
            embeddedImagesDisabled: 0,
            transformOpts: stubbedOptions,
            bodyBanners: []
        )
    }
    
    override func body(opts: TransformOpts) async -> BodyOutput {
        bodyWithOptionsCalls.append(opts)
        
        return .init(
            body: "<html>dummy_with_custom_options</html>",
            hadBlockquote: true,
            tagsStripped: 0,
            utmStripped: 0,
            remoteImagesDisabled: 0,
            embeddedImagesDisabled: 0,
            transformOpts: opts,
            bodyBanners: []
        )
    }

}
