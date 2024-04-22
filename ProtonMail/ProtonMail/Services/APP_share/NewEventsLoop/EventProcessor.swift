// Copyright (c) 2023 Proton Technologies AG
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

import CoreData
import Foundation
@preconcurrency import ProtonCoreDataModel

final class EventProcessor {
    typealias Dependencies = AnyObject
        & HasCoreDataContextProviderProtocol
        & HasIncomingDefaultService
        & HasLastUpdatedStoreProtocol
        & HasNotificationCenter
        & HasUserManager
        & HasUserDefaults
        & SaveEventResponseInCacheUseCase.Dependencies

    private unowned let dependencies: Dependencies
    private lazy var saveEventResponseInCache: SaveEventResponseInCacheUseCase = {
        .init(dependencies: dependencies, userID: userID)
    }()
    private var userID: UserID {
        dependencies.user.userID
    }
    private let serverNotice: ServerNotice

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        self.serverNotice = .init(userDefaults: dependencies.userDefaults)
    }

    func process(response: EventAPIResponse, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            processUsedSpace(response)
            processUserSettings(response)
            processMailSettings(response)
            processUser(response)
            await processAddresses(response)
            processServerNotice(response)

            processIncomingDefaults(response)
            processMessageCount(response)
            processConversationCount(response)
            do {
                try self.saveEventResponseInCache.execute(response: response)
            } catch {
                completion(.failure(error))
            }
            #if DEBUG
            completeClosureCalledCount += 1
            #endif
            completion(.success(()))
        }
    }

    private func processUsedSpace(_ response: EventAPIResponse) {
        guard let usedSpace = response.usedSpace else {
            return
        }
        dependencies.user.update(usedSpace: Int64(usedSpace))
    }

    private func processUserSettings(_ response: EventAPIResponse) {
        guard let userSettings = response.userSettings else {
            return
        }
        let user = dependencies.user
        let shouldUpdateTelemetryOrCrashReport = user.userInfo.hasCrashReportingEnabled.intValue != userSettings.crashReports
            || user.hasTelemetryEnabled.intValue != userSettings.telemetry
        user.userInfo.update(from: userSettings)
        user.updateTelemetryAndCatchCrash()
    }

    private func processMailSettings(_ response: EventAPIResponse) {
        guard let mailSettings = response.mailSettings else {
            return
        }
        dependencies.user.userInfo.update(from: mailSettings)
        dependencies.user.mailSettings = MailSettings(
            nextMessageOnMove: .init(rawValue: mailSettings.nextMessageOnMove),
            hideSenderImages: mailSettings.hideSenderImages == 1,
            showMoved: .init(rawValue: mailSettings.showMoved),
            autoDeleteSpamTrashDays: .init(rawValue: mailSettings.autoDeleteSpamAndTrashDays),
            almostAllMail: mailSettings.almostAllMail == 1
        )
    }

    private func processIncomingDefaults(_ response: EventAPIResponse) {
        guard let incomingDefaults = response.incomingDefaults else {
            return
        }
        for item in incomingDefaults {
            do {
                let action = EventAction(rawValue: item.action) ?? .unknown
                switch action {
                case .delete:
                    try dependencies.incomingDefaultService.hardDelete(query: .id(item.id), includeSoftDeleted: true)
                case .create, .update:
                    guard let incomingDefault = item.incomingDefault,
                          let location = IncomingDefaultsAPI.Location(rawValue: incomingDefault.location) else {
                        continue
                    }
                    let dto = IncomingDefaultDTO(
                        email: incomingDefault.email,
                        id: incomingDefault.id,
                        location: location,
                        time: Date(timeIntervalSince1970: TimeInterval(incomingDefault.time))
                    )
                    try dependencies.incomingDefaultService.save(dto: dto)
                default:
                    break
                }
            } catch {
                PMAssertionFailure(error)
            }
        }
    }

    private func processAddresses(_ response: EventAPIResponse) async {
        guard let addresses = response.addresses else {
            return
        }

        for addressEvent in addresses {
            guard let eventAction = EventAction(rawValue: addressEvent.action) else {
                continue
            }
            switch eventAction {
            case .delete:
                dependencies.user.deleteFromEvents(addressIDRes: addressEvent.id)
            case .create, .update:
                guard let address = addressEvent.address else {
                    continue
                }
                let addressModel = address.convertToProtonAddressModel()
                dependencies.user.setFromEvents(addressRes: addressModel)
                do {
                    try await dependencies.user.userService.activeUserKeys(
                        userInfo: dependencies.user.userInfo,
                        auth: dependencies.user.authCredential
                    )
                } catch {
                    PMAssertionFailure(error)
                }
            default:
                break
            }
        }
        dependencies.notificationCenter.post(name: .addressesStatusAreChanged, object: nil)
    }

    private func processUser(_ response: EventAPIResponse) {
        guard let user = response.user else {
            return
        }
        dependencies.user.userInfo.update(from: user)
    }

    private func processMessageCount(_ response: EventAPIResponse) {
        guard let messageCounts = response.messageCounts else {
            return
        }
        do {
            try dependencies.lastUpdatedStore.batchUpdateUnreadCounts(
                counts: messageCounts,
                userID: userID,
                type: .singleMessage
            )
        } catch {
            PMAssertionFailure(error)
        }
    }

    private func processConversationCount(_ response: EventAPIResponse) {
        guard let conversationCounts = response.conversationCounts else {
            return
        }
        do {
            try dependencies.lastUpdatedStore.batchUpdateUnreadCounts(
                counts: conversationCounts,
                userID: userID,
                type: .conversation
            )
        } catch {
            PMAssertionFailure(error)
        }
    }

    private func processServerNotice(_ response: EventAPIResponse) {
        serverNotice.check(response.notices)
    }

    #if DEBUG
    var completeClosureCalledCount = 0
    #endif
}
