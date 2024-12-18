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

/**
 This protocol is created on the client side to use it insead of the SDK's `DraftProtocol`

 The reason is `DraftProtocol` created by uniffi does not use the `ComponentRecipientListProtocol` in
 its function definitions. Given that we can't instantiate `ComponentRecipientList` objects, we are forced
 to work with our own draft protocol
 */
public protocol AppDraftProtocol {

    /// These are the function we overwrite from the `DraftProtocol`. For every function
    /// returning `ComposerRecipientList`, we return `ComposerRecipientListProtocol`.
    func toRecipients() -> ComposerRecipientListProtocol
    func ccRecipients() -> ComposerRecipientListProtocol
    func bccRecipients() -> ComposerRecipientListProtocol

    /// These function definitions must replicate whatever the `DraftProtocol` declares except the
    /// ones that return `ComposerRecipientList` objects.
    func messageId() async -> OptIdDraftResult
    func attachments()  -> [AttachmentMetadata]
    func body()  -> String
    func mimeType()  -> MimeType
    func save() async  -> VoidDraftResult
    func send() async  -> VoidDraftResult
    func sender()  -> String
    func setBody(body: String)  -> VoidDraftResult
    func setSubject(subject: String)  -> VoidDraftResult
    func subject()  -> String
}

/**
 This conformance allows us to use `Draft` as an `AppDraftProtocol`
 */
extension Draft: AppDraftProtocol {
    public func toRecipients() -> ComposerRecipientListProtocol {
        let list: ComposerRecipientList = self.toRecipients()
        return list
    }

    public func ccRecipients() -> ComposerRecipientListProtocol {
        let list: ComposerRecipientList = self.ccRecipients()
        return list
    }

    public func bccRecipients() -> ComposerRecipientListProtocol {
        let list: ComposerRecipientList = self.bccRecipients()
        return list
    }
}
