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

import proton_mail_uniffi
import SwiftUI

final class SidebarScreenModel: ObservableObject, Sendable {
    @ObservedObject private var appRoute: AppRouteState

    private(set) var systemFolders: [SidebarCellUIModel]
    private var systemFolderQuery: MailLabelsLiveQuery?
    private let dependencies: Dependencies

    var route: Route {
        appRoute.route
    }

    init(appRoute: AppRouteState, systemFolders: [SidebarCellUIModel] = [], dependencies: Dependencies = .init()) {
        self.appRoute = appRoute
        self.systemFolders = systemFolders
        self.dependencies = dependencies
    }

    func onViewWillAppear() async {
        await initLiveQuery()
    }

    private func initLiveQuery() async {
        do {
            guard let userContext = try await dependencies.appContext.userContextForActiveSession() else {
                return
            }
            systemFolderQuery = userContext.newSystemLabelsObservedQuery(cb: self)
        } catch {
            AppLogger.log(error: error, category: .rustLibrary)
        }
    }

    @MainActor
    private func updateData() {
        guard let systemFolderQuery else { return }
        let folders = systemFolderQuery.value()
        setInitialFolderIfNeeded(from: folders)
        systemFolders = folders.compactMap { $0.systemFolderToSidebarCellUIModel() }
    }

    private func setInitialFolderIfNeeded(from folders: [LocalLabelWithCount]) {
        guard appRoute.selectedMailbox == .placeHolderMailbox, let firstSystemFolders = folders.first else { return }
        var systemFolder: SystemFolderIdentifier? = nil
        if let rid = firstSystemFolders.rid, let remoteId = UInt64(rid) {
            systemFolder = SystemFolderIdentifier(rawValue: remoteId)
        }
        appRoute.updateRoute(
            to: .mailbox(
                label: .init(
                    localId: firstSystemFolders.id,
                    name: firstSystemFolders.name,
                    systemFolder: systemFolder
                )
            )
        )
    }

    @MainActor
    func updateRoute(newRoute: Route) {
        appRoute.updateRoute(to: newRoute)
    }
}

extension SidebarScreenModel: MailboxLiveQueryUpdatedCallback {
    
    func onUpdated() {
        Task {
            await updateData()
        }
    }
}

extension SidebarScreenModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
