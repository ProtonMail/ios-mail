//
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

import InboxTesting
import proton_app_uniffi
import Testing

@testable import InboxComposer
@testable import TestableShareExtension

@MainActor
final class ShareScreenModelTests {
    private let extensionContext = ExtensionContextSpy()
    private let mailSession = MailSessionSpy()
    private var stubbedMailSessionResult: Result<MailSessionProtocol, TestError>
    private var stubbedNewDraftResult: Result<AppDraftProtocol, TestError>

    private lazy var sut = ShareScreenModel(
        apiEnvId: .atlas,
        extensionContext: extensionContext,
        makeMailSession: { [unowned self] _, _, _, _ in
            try stubbedMailSessionResult.get()
        },
        makeNewDraft: { [unowned self] _, _ in
            try stubbedNewDraftResult.get()
        }
    )

    init() {
        mailSession.primaryUserSessionStub = MailUserSessionSpy(id: "")
        stubbedMailSessionResult = .success(mailSession)
        stubbedNewDraftResult = .success(MockDraft.emptyMockDraft)
    }

    @Test(arguments: [AppProtection.biometrics, .pin])
    func showsLockScreenIfAppProtectionIsSet(appProtection: AppProtection) async {
        mailSession.appProtectionStub = appProtection

        await sut.prepare()

        switch sut.state {
        case .locked(appProtection.lockScreenType, _):
            break
        default:
            Issue.record("unexpected state: \(sut.state)")
        }
    }

    @Test
    func showsComposerIfAppProtectionIsNotSet() async {
        mailSession.appProtectionStub = .none

        await sut.prepare()

        switch sut.state {
        case .composing:
            break
        default:
            Issue.record("unexpected state: \(sut.state)")
        }
    }

    @Test
    func showsErrorScreenIfInitialSetupFails() async throws {
        stubbedMailSessionResult = .failure(TestError())

        await sut.prepare()

        switch sut.state {
        case .error(_ as TestError):
            break
        default:
            Issue.record("unexpected state: \(sut.state)")
        }
    }

    @Test
    func showsErrorScreenIfPreparingComposerScreenFails() async throws {
        stubbedNewDraftResult = .failure(TestError())

        await sut.prepare()

        switch sut.state {
        case .error(_ as TestError):
            break
        default:
            Issue.record("unexpected state: \(sut.state)")
        }
    }

    @Test
    func dismissingWithErrorCancelsTheRequestOfTheContext() {
        sut.dismissShareExtension(error: TestError())

        #expect(extensionContext.cancelRequestInvocations.count == 1)
        #expect(extensionContext.cancelRequestInvocations.first is TestError)
        #expect(extensionContext.completeRequestInvocations.count == 0)
    }

    @Test(arguments: [true, false])
    func dismissingWithoutErrorCompletesTheRequestOfTheContext(expirationFlag: Bool) {
        extensionContext.stubbedExpirationFlag = expirationFlag

        sut.dismissShareExtension(error: nil)

        #expect(extensionContext.completeRequestInvocations.count == 1)
        #expect(extensionContext.cancelRequestInvocations.count == 0)
    }
}
