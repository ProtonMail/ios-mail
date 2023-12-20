//
//  AttachmentViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Combine

final class AttachmentViewModel {
    typealias Dependencies = HasEventRSVP
    & HasFeatureFlagProvider
    & HasFetchAttachmentUseCase
    & HasFetchAttachmentMetadataUseCase
    & HasUserManager

    private(set) var attachments: Set<AttachmentInfo> = [] {
        didSet {
            reloadView?()
            if oldValue != attachments {
                checkAttachmentsForInvitations()
            }
        }
    }
    var reloadView: (() -> Void)?

    var numberOfAttachments: Int {
        attachments.count
    }

    var invitationViewState: AnyPublisher<InvitationViewState, Never> {
        invitationViewSubject.eraseToAnyPublisher()
    }

    var totalSizeOfAllAttachments: Int {
        let attachmentSizes = attachments.map({ $0.size })
        let totalSize = attachmentSizes.reduce(0) { result, value -> Int in
            return result + value
        }
        return totalSize
    }

    private let invitationViewSubject = CurrentValueSubject<InvitationViewState, Never>(.noInvitationFound)

    private var invitationProcessingTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func attachmentHasChanged(nonInlineAttachments: [AttachmentInfo], mimeAttachments: [MimeAttachment]) {
        var files: [AttachmentInfo] = nonInlineAttachments
        files.append(contentsOf: mimeAttachments)
        self.attachments = Set(files)
    }

    private func checkAttachmentsForInvitations() {
        guard
            dependencies.featureFlagProvider.isEnabled(.rsvpWidget),
            let ics = attachments.first(where: { $0.type == .calendar })
        else {
            return
        }

        invitationViewSubject.send(.invitationFoundAndProcessing)

        invitationProcessingTask = Task {
            do {
                let icsData = try await fetchAndDecrypt(ics: ics)
                let eventDetails = try await dependencies.eventRSVP.parseData(icsData: icsData)
                invitationViewSubject.send(.invitationProcessed(eventDetails))
            } catch {
                PMAssertionFailure(error)
                invitationViewSubject.send(.noInvitationFound)
            }
        }
    }

    private func fetchAndDecrypt(ics: AttachmentInfo) async throws -> Data {
        let attachmentMetadata = try await dependencies.fetchAttachmentMetadata.execution(
            params: .init(attachmentID: ics.id)
        )

        let attachment = try await dependencies.fetchAttachment.execute(
            params: .init(
                attachmentID: ics.id,
                attachmentKeyPacket: attachmentMetadata.keyPacket,
                userKeys: dependencies.user.toUserKeys()
            )
        )

        return attachment.data
    }
}

extension AttachmentViewModel {
    enum InvitationViewState: Equatable {
        case noInvitationFound
        case invitationFoundAndProcessing
        case invitationProcessed(EventDetails)
    }
}
