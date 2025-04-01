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

@testable import InboxComposer
import proton_app_uniffi
import Testing

final class RecipientUIModelArrayTests {
    private var sut: [RecipientUIModel]!
    private var validRecipient1: RecipientUIModel!
    private var validRecipient2: RecipientUIModel!
    private var invalidRecipient2AddressDoesNotExistError: RecipientUIModel!
    private var invalidRecipient2UnknownError: RecipientUIModel!

    init() {
        let singleRecipient1 = ComposerRecipientSingle(displayName: "Alice", address: "alice@example.com", validState: .valid)
        let singleRecipient2 = ComposerRecipientSingle(displayName: "Bob", address: "bob@example.com", validState: .valid)

        validRecipient1 = singleRecipient1.toRecipientUIModel
        validRecipient2 = singleRecipient2.toRecipientUIModel
        invalidRecipient2AddressDoesNotExistError = singleRecipient2.makeInvalid(.doesNotExist).toRecipientUIModel
        invalidRecipient2UnknownError = singleRecipient2.makeInvalid(.unknown).toRecipientUIModel
    }

    deinit {
        validRecipient1 = nil
        validRecipient2 = nil
        invalidRecipient2AddressDoesNotExistError = nil
        sut = nil
    }

    // MARK: hasNewDoesNotExistAddressError

    @Test
    func testHasNewDoesNotExistAddressError_whenThereIsNoNewError_itReturnsFalse() throws {
        let oldRecipients: [RecipientUIModel] = [validRecipient1]
        sut = [validRecipient1, validRecipient2]

        #expect(sut.hasNewDoesNotExistAddressError(comparedTo: oldRecipients) == false)
    }

    @Test
    func testHasNewDoesNotExistAddressError_whenThereIsAnAddressDoesNotExistError_itReturnsTrue() throws {
        let oldRecipients: [RecipientUIModel] = [validRecipient1, validRecipient2]
        sut = [validRecipient1, invalidRecipient2AddressDoesNotExistError]

        #expect(sut.hasNewDoesNotExistAddressError(comparedTo: oldRecipients) == true)
    }

    @Test
    func testHasNewDoesNotExistAddressError_whenThereIsAnUnknownError_itReturnsFalse() throws {
        let oldRecipients: [RecipientUIModel] = [validRecipient1, validRecipient2]
        sut = [validRecipient1, invalidRecipient2UnknownError]

        #expect(sut.hasNewDoesNotExistAddressError(comparedTo: oldRecipients) == false)
    }
}

private extension ComposerRecipientSingle {

    var toRecipientUIModel: RecipientUIModel {
        RecipientUIModel(composerRecipient: .single(self))
    }

    func makeInvalid(_ reason: RecipientInvalidReason) -> Self {
        var invalid = self
        invalid.validState = .invalid(reason)
        return invalid
    }
}
