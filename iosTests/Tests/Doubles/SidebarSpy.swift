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

@testable import ProtonMail
import proton_mail_uniffi

class SidebarSpy: SidebarProtocol {

    var stubbedSystemLabels: [PMSystemLabel] = []
    var stubbedCustomFolders: [PMCustomFolder] = []
    var stubbedCustomLabels: [PMCustomLabel] = []
    private(set) var spiedWatchers: [LabelType: LiveQueryCallback] = [:]

    // MARK: - SidebarProtocol

    func allCustomFolders() async throws -> [SidebarCustomFolder] {
        stubbedCustomFolders
    }

    func collapseFolder(localId: Id) async throws {
        notImplemented()
    }

    func customFolders() async throws -> [SidebarCustomFolder] {
        stubbedCustomFolders
    }

    func customLabels() async throws -> [SidebarCustomLabel] {
        stubbedCustomLabels
    }

    func expandFolder(localId: Id) async throws {
        notImplemented()
    }

    func systemLabels() async throws -> [SidebarSystemLabel] {
        stubbedSystemLabels
    }

    func watchLabels(labelType: LabelType, callback: LiveQueryCallback) async throws -> WatchHandle {
        spiedWatchers[labelType] = callback

        return WatchHandle(noPointer: .init())
    }

}

private func notImplemented() -> Never {
    fatalError("Not implemented")
}
