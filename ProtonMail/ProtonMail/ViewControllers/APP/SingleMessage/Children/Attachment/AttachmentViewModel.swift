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
import ProtonCoreDataModel
import ProtonCoreUtilities
import ProtonInboxRSVP

final class AttachmentViewModel {
    typealias Dependencies = HasAnswerInvitation
    & HasExtractBasicEventInfo
    & HasFeatureFlagProvider
    & HasFetchAttachmentUseCase
    & HasFetchAttachmentMetadataUseCase
    & HasFetchEventDetails
    & HasURLOpener
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

    var error: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var invitationViewState: AnyPublisher<InvitationViewState, Never> {
        invitationViewSubject.eraseToAnyPublisher()
    }

    var respondingStatus: AnyPublisher<RespondingStatus, Never> {
        respondingStatusSubject.eraseToAnyPublisher()
    }

    var totalSizeOfAllAttachments: Int {
        let attachmentSizes = attachments.map({ $0.size })
        let totalSize = attachmentSizes.reduce(0) { result, value -> Int in
            return result + value
        }
        return totalSize
    }

    var basicEventInfoSourcedFromHeaders: BasicEventInfo? {
        didSet {
            if let basicEventInfoSourcedFromHeaders, basicEventInfoSourcedFromHeaders != oldValue {
                fetchEventDetails(initialInfo: .right(basicEventInfoSourcedFromHeaders))
            }
        }
    }

    var viewShouldBeShown: Bool {
        numberOfAttachments != 0 || basicEventInfoSourcedFromHeaders != nil
    }

    private let errorSubject = PassthroughSubject<Error, Never>()
    private let invitationViewSubject = CurrentValueSubject<InvitationViewState, Never>(.noInvitationFound)
    private let respondingStatusSubject = CurrentValueSubject<RespondingStatus, Never>(.respondingUnavailable)

    private var invitationProcessingTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }

    private var answeringContext: AnsweringContext?

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
            basicEventInfoSourcedFromHeaders == nil,
            let ics = attachments.first(where: { $0.type == .calendar })
        else {
            return
        }

        fetchEventDetails(initialInfo: .left(ics))
    }

    private func fetchEventDetails(initialInfo: Either<AttachmentInfo, BasicEventInfo>) {
        guard dependencies.featureFlagProvider.isEnabled(.rsvpWidget) else {
            return
        }

        invitationViewSubject.send(.invitationFoundAndProcessing)

        invitationProcessingTask = Task { [weak self] in
            guard let self else { return }

            do {
                let basicEventInfo: BasicEventInfo

                switch initialInfo {
                case .left(let attachmentInfo):
                    let icsData = try await fetchAndDecrypt(ics: attachmentInfo)
                    basicEventInfo = try dependencies.extractBasicEventInfo.execute(icsData: icsData)
                case .right(let value):
                    basicEventInfo = value
                }

                let (eventDetails, answeringContext) = try await dependencies.fetchEventDetails.execute(
                    basicEventInfo: basicEventInfo
                )

                self.answeringContext = answeringContext
                invitationViewSubject.send(.invitationProcessed(eventDetails))
                updateRespondingOptions(eventDetails: eventDetails)
            } catch {
                invitationViewSubject.send(.noInvitationFound)

                switch error {
                case EventRSVPError.icsDoesNotContainSupportedMethod, EventRSVPError.noEventsReturnedFromAPI:
                    break
                default:
                    errorSubject.send(error)
                }
            }
        }
    }

    private func fetchAndDecrypt(ics: AttachmentInfo) async throws -> Data {
        if let localUrl = ics.localUrl, let data = try? Data(contentsOf: localUrl) {
            return data
        }

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

    func respondToInvitation(with answer: AttendeeStatusDisplay) {
        // store this in case the update fails
        let currentValue = respondingStatusSubject.value

        respondingStatusSubject.send(.responseIsBeingProcessed)

        Task {
            do {
                let parameters = AnswerInvitationWrapper.Parameters(
                    answer: answer,
                    context: answeringContext
                )

                try await dependencies.answerInvitation.execute(parameters: parameters)

                respondingStatusSubject.send(.alreadyResponded(answer))
            } catch {
                errorSubject.send(error)
                respondingStatusSubject.send(currentValue)
            }
        }
    }

    func instructionToHandle(deepLink: URL) -> OpenInCalendarInstruction {
        if dependencies.urlOpener.canOpenURL(deepLink) {
            return .openDeepLink(deepLink)
        } else if dependencies.urlOpener.canOpenURL(.ProtonCalendar.legacyScheme) {
            return .promptToUpdateCalendarApp
        } else if dependencies.featureFlagProvider.isEnabled(.calendarMiniLandingPage) {
            return .presentCalendarLandingPage
        } else {
            return .goToAppStoreDirectly
        }
    }

    private func updateRespondingOptions(eventDetails: EventDetails) {
        guard
            dependencies.featureFlagProvider.isEnabled(.answerInvitation),
            eventDetails.status != .cancelled,
            let currentUserAmongInvitees = eventDetails.currentUserAmongInvitees
        else {
            return
        }

        switch currentUserAmongInvitees.status {
        case .accepted:
            respondingStatusSubject.send(.alreadyResponded(.yes))
        case .declined:
            respondingStatusSubject.send(.alreadyResponded(.no))
        case .tentative:
            respondingStatusSubject.send(.alreadyResponded(.maybe))
        default:
            respondingStatusSubject.send(.awaitingUserInput)
        }
    }
}

extension AttachmentViewModel {
    enum OpenInCalendarInstruction: Equatable {
        case openDeepLink(URL)
        case promptToUpdateCalendarApp
        case goToAppStoreDirectly
        case presentCalendarLandingPage
    }

    enum RespondingStatus: Equatable {
        case respondingUnavailable
        case awaitingUserInput
        case responseIsBeingProcessed
        case alreadyResponded(AttendeeStatusDisplay)
    }

    enum InvitationViewState: Equatable {
        case noInvitationFound
        case invitationFoundAndProcessing
        case invitationProcessed(EventDetails)
    }
}
