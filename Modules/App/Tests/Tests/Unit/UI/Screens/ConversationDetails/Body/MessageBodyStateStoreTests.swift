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

import ProtonUIFoundations
import Testing
import proton_app_uniffi

@testable import InboxCore
@testable import InboxCoreUI
@testable import ProtonMail

@Suite(.serialized) @MainActor
final class MessageBodyStateStoreTests {
    private lazy var sut = MessageBodyStateStore(
        messageID: stubbedMessageID,
        mailbox: .dummy,
        wrapper: wrapperSpy.testingInstance,
        toastStateStore: toastStateStore,
        backOnlineActionExecutor: backOnlineActionExecutorSpy
    )
    private let stubbedMessageID = ID(value: 42)
    private let toastStateStore = ToastStateStore(initialState: .initial)
    private let wrapperSpy = RustWrappersSpy()
    private let backOnlineActionExecutorSpy = BackOnlineActionExecutorSpy()

    // MARK: - `onLoad` action

    @Test
    func testState_WhenOnLoadAndSucceedsFetchingBody_ItReturnsLoadedWithCorrectMessageBody() async {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)

        #expect(wrapperSpy.messageBodyCalls == [])
        #expect(decryptedMessageSpy.bodyWithOptionsCalls.count == 0)
        #expect(sut.state == .init(body: .fetching, alert: .none))

        await sut.handle(action: .onLoad)

        #expect(wrapperSpy.messageBodyCalls == [stubbedMessageID])
        #expect(decryptedMessageSpy.bodyWithOptionsCalls.count == 1)
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: initialOptions,
                    decryptedMessage: decryptedMessageSpy
                ))
    }

    @Test
    func testState_WhenOnLoadAndFailedDueToNetworkError_ItReturnsNoConnectionErrorAndThenReloads() async {
        wrapperSpy.stubbedMessageBodyResult = .error(.other(.network))

        await sut.handle(action: .onLoad)

        #expect(wrapperSpy.messageBodyCalls == [stubbedMessageID])
        #expect(sut.state == .init(body: .noConnection, alert: .none))

        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: TransformOpts())
        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)

        #expect(backOnlineActionExecutorSpy.executeCalled.count == 1)
        await backOnlineActionExecutorSpy.executeCalled.first?()

        #expect(decryptedMessageSpy.bodyWithOptionsCalls.count == 1)
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: initialOptions,
                    decryptedMessage: decryptedMessageSpy
                ))
    }

    @Test
    func testState_WhenOnLoadAndFailedDueToOtherReasonError_ItReturnsError() async {
        let expectedError: ActionError = .other(.otherReason(.other("An error occurred")))

        wrapperSpy.stubbedMessageBodyResult = .error(expectedError)

        await sut.handle(action: .onLoad)

        #expect(wrapperSpy.messageBodyCalls == [stubbedMessageID])
        #expect(sut.state == .init(body: .error(expectedError), alert: .none))
    }

    // MARK: - `refreshBanners` action

    @Test
    func testState_WhenRefreshBannersActionTriggered_ItFetchesBodyWithSameOptions() async {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)

        await sut.handle(action: .onLoad)

        #expect(wrapperSpy.messageBodyCalls == [stubbedMessageID])
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: initialOptions,
                    decryptedMessage: decryptedMessageSpy
                ))

        await sut.handle(action: .refreshBanners)

        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions, initialOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: initialOptions,
                    decryptedMessage: decryptedMessageSpy
                ))
    }

    // MARK: - `displayEmbeddedImagesTapped` action

    @Test
    func testState_WhenDisplayEmbeddedImagesActionTriggered_ItFetchesBodyWithModifiedOptions() async {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)

        await sut.handle(action: .onLoad)

        #expect(wrapperSpy.messageBodyCalls == [stubbedMessageID])
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: initialOptions,
                    decryptedMessage: decryptedMessageSpy
                ))

        await sut.handle(action: .displayEmbeddedImages)

        let updatedOptions = initialOptions.copy(\.hideEmbeddedImages, to: false)

        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions, updatedOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: updatedOptions,
                    decryptedMessage: decryptedMessageSpy
                ))
    }

    // MARK: - `downloadRemoteContentTapped` action

    @Test
    func testState_WhenDownloadRemoteContentActionTriggered_ItFetchesBodyWithModifiedOptions() async {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)

        await sut.handle(action: .onLoad)

        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: initialOptions,
                    decryptedMessage: decryptedMessageSpy
                ))

        await sut.handle(action: .downloadRemoteContent)

        let updatedOptions = initialOptions.copy(\.hideRemoteImages, to: false)

        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions, updatedOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: updatedOptions,
                    decryptedMessage: decryptedMessageSpy
                ))
    }

    // MARK: - `markAsLegitimate` action

    @Test
    func testState_WhenMarkAsLegitimateActionTapped_ItPresentsConfirmationAlert() async {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        wrapperSpy.stubbedMarkMessageHamResult = .ok

        await sut.handle(action: .onLoad)
        await sut.handle(action: .displayEmbeddedImages)

        let updatedOptions = initialOptions.copy(\.hideEmbeddedImages, to: false)

        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions, updatedOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: updatedOptions,
                    decryptedMessage: decryptedMessageSpy
                ))

        await sut.handle(action: .markAsLegitimate)

        #expect(wrapperSpy.markMessageHamCalls == [])
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions, updatedOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: updatedOptions,
                    decryptedMessage: decryptedMessageSpy,
                    alert: .legitMessageConfirmation(action: { _ in })
                ))
    }

    @Test
    func testState_WhenMarkAsLegitimateConfirmedAndSucceeds_ItMarksMessageHamAndFetchesBodyAgain() async throws {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        wrapperSpy.stubbedMarkMessageHamResult = .ok

        await sut.handle(action: .onLoad)
        await sut.handle(action: .markAsLegitimate)

        let markAsLegitimateAction = try sut.state.legitAlertAction(for: .markAsLegitimate)
        await markAsLegitimateAction.action()

        #expect(wrapperSpy.markMessageHamCalls == [stubbedMessageID])
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions, initialOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: initialOptions,
                    decryptedMessage: decryptedMessageSpy
                ))
    }

    @Test
    func testState_WhenSpamMarkAsLegitimateConfirmedAndFails_ItDoesNotFetchBodyAndPresentsErrorToast() async throws {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)
        let expectedActionError: ActionError = .other(.network)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        wrapperSpy.stubbedMarkMessageHamResult = .error(expectedActionError)

        await sut.handle(action: .onLoad)
        await sut.handle(action: .markAsLegitimate)

        let markAsLegitimateAction = try sut.state.legitAlertAction(for: .markAsLegitimate)
        await markAsLegitimateAction.action()

        #expect(wrapperSpy.markMessageHamCalls == [stubbedMessageID])
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions])
        #expect(toastStateStore.state.toasts == [.error(message: expectedActionError.localizedDescription)])
    }

    @Test
    func testState_WhenMarkAsLegitimateCancelled_ItDoesNotMarkMessageHam() async throws {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        wrapperSpy.stubbedMarkMessageHamResult = .ok

        await sut.handle(action: .onLoad)
        await sut.handle(action: .markAsLegitimate)

        let cancelAction = try sut.state.legitAlertAction(for: .cancel)
        await cancelAction.action()

        #expect(wrapperSpy.markMessageHamCalls == [])
        #expect(decryptedMessageSpy.bodyWithOptionsCalls.count == 1)
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: initialOptions,
                    decryptedMessage: decryptedMessageSpy
                ))
    }

    // MARK: - `unblockSender` action

    @Test
    func testState_WhenUnblockSenderActionSucceeds_ItUnblocksSenderAndFetchesBodyAgain() async {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        wrapperSpy.stubbedUnblockSenderResult = .ok

        await sut.handle(action: .onLoad)
        await sut.handle(action: .displayEmbeddedImages)

        let updatedOptions = initialOptions.copy(\.hideEmbeddedImages, to: false)

        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions, updatedOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: updatedOptions,
                    decryptedMessage: decryptedMessageSpy
                ))

        let emailAddress = "john.doe@pm.me"
        await sut.handle(action: .unblockSender(emailAddress: emailAddress))

        #expect(wrapperSpy.unblockSenderCalls == [emailAddress])
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions, updatedOptions, updatedOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: updatedOptions,
                    decryptedMessage: decryptedMessageSpy
                ))
    }

    @Test
    func testState_WhenUnblockSenderActionFails_ItDoesNotFetchBodyAndPresentsErrorToast() async {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)
        let expectedActionError: ActionError = .other(.network)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        wrapperSpy.stubbedUnblockSenderResult = .error(expectedActionError)

        await sut.handle(action: .onLoad)
        await sut.handle(action: .displayEmbeddedImages)

        let updatedOptions = initialOptions.copy(\.hideEmbeddedImages, to: false)

        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions, updatedOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: updatedOptions,
                    decryptedMessage: decryptedMessageSpy
                ))

        let emailAddress = "steven.morcote@pm.me"
        await sut.handle(action: .unblockSender(emailAddress: emailAddress))

        #expect(wrapperSpy.unblockSenderCalls == [emailAddress])
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions, updatedOptions])
        #expect(toastStateStore.state.toasts == [.error(message: expectedActionError.localizedDescription)])
    }

    // MARK: - `unsubscribeNewsletter` action

    @Test
    func testState_UnsubscribeNewsletterActionTapped_ItPresentsConfirmationAlert() async {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        decryptedMessageSpy.stubbedUnsubscribeFromNewsletterResult = .ok

        await sut.handle(action: .onLoad)
        await sut.handle(action: .unsubscribeNewsletter)

        #expect(decryptedMessageSpy.unsubscribeFromNewsletterCallsCount == 0)
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: initialOptions,
                    decryptedMessage: decryptedMessageSpy,
                    alert: .unsubcribeNewsletter(action: { _ in })
                ))
        #expect(toastStateStore.state.toasts == [])
    }

    @Test
    func testState_UnsubscribeNewsletterConfirmedAndSucceeds_ItUnsubscribesAndFetchesBodyAgain() async throws {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        decryptedMessageSpy.stubbedUnsubscribeFromNewsletterResult = .ok

        await sut.handle(action: .onLoad)
        await sut.handle(action: .unsubscribeNewsletter)

        let unsubscribeAction = try sut.state.unsubscribeAlertAction(for: .unsubscribe)
        await unsubscribeAction.action()

        #expect(decryptedMessageSpy.unsubscribeFromNewsletterCallsCount == 1)
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions, initialOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: initialOptions,
                    decryptedMessage: decryptedMessageSpy,
                ))
        #expect(
            toastStateStore.state.toasts == [
                .information(message: L10n.MessageBanner.UnsubscribeNewsletter.Toast.success.string)
            ]
        )
    }

    @Test
    func testState_UnsubscribeNewsletterConfirmedAndFails_ItPresentsErrorToast() async throws {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)
        let expectedActionError: ActionError = .reason(.unknownMessage)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        decryptedMessageSpy.stubbedUnsubscribeFromNewsletterResult = .error(expectedActionError)

        await sut.handle(action: .onLoad)
        await sut.handle(action: .unsubscribeNewsletter)

        let unsubscribeAction = try sut.state.unsubscribeAlertAction(for: .unsubscribe)
        await unsubscribeAction.action()

        #expect(decryptedMessageSpy.unsubscribeFromNewsletterCallsCount == 1)
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: initialOptions,
                    decryptedMessage: decryptedMessageSpy
                ))
        #expect(toastStateStore.state.toasts == [.error(message: expectedActionError.localizedDescription)])
    }

    @Test
    func testState_WhenUnsubscribeNewsletterCancelled_ItDoesNotUnsubscribe() async throws {
        let initialOptions = TransformOpts()
        let decryptedMessageSpy = DecryptedMessageSpy(stubbedOptions: initialOptions)

        wrapperSpy.stubbedMessageBodyResult = .ok(decryptedMessageSpy)
        decryptedMessageSpy.stubbedUnsubscribeFromNewsletterResult = .ok

        await sut.handle(action: .onLoad)
        await sut.handle(action: .unsubscribeNewsletter)

        let cancelAction = try sut.state.unsubscribeAlertAction(for: .cancel)
        await cancelAction.action()

        #expect(decryptedMessageSpy.unsubscribeFromNewsletterCallsCount == 0)
        #expect(decryptedMessageSpy.bodyWithOptionsCalls == [initialOptions])
        #expect(
            sut.state
                == .noBannersAlert(
                    rawBody: "<html>dummy_with_custom_options</html>",
                    options: initialOptions,
                    decryptedMessage: decryptedMessageSpy,
                ))
        #expect(toastStateStore.state.toasts == [])
    }
}

extension MessageBodyStateStore.State: @retroactive Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.alert == rhs.alert else {
            return false
        }

        switch (lhs.body, rhs.body) {
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
        let areRsvpProviderEqual: Bool = lhs.rsvpServiceProvider === rhs.rsvpServiceProvider
        let areNewsletterServicesEqual = lhs.newsletterService === rhs.newsletterService
        let areHTMLsEqual =
            lhs.html.rawBody == rhs.html.rawBody && lhs.html.options == rhs.html.options && lhs.html.imageProxy === rhs.html.imageProxy
        let areBannersEqual = lhs.banners == rhs.banners

        return areRsvpProviderEqual && areNewsletterServicesEqual && areHTMLsEqual && areBannersEqual
    }

}

private final class DecryptedMessageSpy: DecryptedMessage, @unchecked Sendable {
    private let stubbedOptions: TransformOpts
    var stubbedUnsubscribeFromNewsletterResult: VoidActionResult = .ok

    init(stubbedOptions: TransformOpts) {
        self.stubbedOptions = stubbedOptions
        super.init(noPointer: .init())
    }

    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    private(set) var bodyWithOptionsCalls: [TransformOpts] = []
    private(set) var unsubscribeFromNewsletterCallsCount: Int = 0

    // MARK: - DecryptedMessage

    override func body(opts: TransformOpts) async -> BodyOutputResult {
        bodyWithOptionsCalls.append(opts)

        return .ok(
            .init(
                body: "<html>dummy_with_custom_options</html>",
                hadBlockquote: true,
                tagsStripped: 0,
                utmStripped: 0,
                remoteImagesDisabled: 0,
                embeddedImagesDisabled: 0,
                transformOpts: opts,
                bodyBanners: []
            ))
    }

    override func identifyRsvp() async -> RsvpEventServiceProvider? {
        nil
    }

    override func unsubscribeFromNewsletter() async -> VoidActionResult {
        unsubscribeFromNewsletterCallsCount += 1

        return stubbedUnsubscribeFromNewsletterResult
    }
}

private final class RustWrappersSpy: @unchecked Sendable {
    var stubbedMessageBodyResult: GetMessageBodyResult!
    private(set) var messageBodyCalls: [ID] = []

    var stubbedMarkMessageHamResult: VoidActionResult = .ok
    private(set) var markMessageHamCalls: [ID] = []

    var stubbedUnblockSenderResult: VoidActionResult = .ok
    private(set) var unblockSenderCalls: [String] = []

    private(set) lazy var testingInstance = RustMessageBodyWrapper(
        messageBody: { [unowned self] _, messageID in
            messageBodyCalls.append(messageID)
            return stubbedMessageBodyResult
        },
        markMessageHam: { [unowned self] _, messageID in
            markMessageHamCalls.append(messageID)
            return stubbedMarkMessageHamResult
        },
        unblockSender: { [unowned self] _, emailAddress in
            unblockSenderCalls.append(emailAddress)
            return stubbedUnblockSenderResult
        }
    )
}

private extension MessageBodyStateStore.State {

    func legitAlertAction(for action: LegitMessageConfirmationAlertAction) throws -> AlertAction {
        try #require(alert?.actions.findFirst(for: action.info.title, by: \.title))
    }

    func unsubscribeAlertAction(for action: UnsubscribeNewsletterAlertAction) throws -> AlertAction {
        try #require(alert?.actions.findFirst(for: action.info.title, by: \.title))
    }

}

private extension MessageBodyStateStore.State {

    static func noBannersAlert(
        rawBody: String,
        options: TransformOpts,
        decryptedMessage: DecryptedMessageSpy,
        alert: AlertModel? = .none
    ) -> Self {
        .init(
            body: .loaded(
                .init(
                    rsvpServiceProvider: .none,
                    newsletterService: decryptedMessage,
                    banners: [],
                    html: .init(rawBody: rawBody, options: options, imageProxy: decryptedMessage)
                )
            ),
            alert: alert
        )
    }

}

private class BackOnlineActionExecutorSpy: BackOnlineActionExecuting {
    private(set) var executeCalled: [() async -> Void] = []

    func execute(action: @escaping @MainActor @Sendable () async -> Void) {
        executeCalled.append(action)
    }
}
