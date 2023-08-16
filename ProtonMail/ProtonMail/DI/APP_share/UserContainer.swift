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

import Factory

final class UserContainer: ManagedContainer {
    let manager = ContainerManager()
    let userManager: UserManager
    let globalContainer: GlobalContainer

    var composerViewFactoryFactory: Factory<ComposerViewFactory> {
        self {
            ComposerViewFactory(dependencies: self)
        }
    }

    var fetchAndVerifyContactsFactory: Factory<FetchAndVerifyContacts> {
        self {
            FetchAndVerifyContacts(user: self.user)
        }
    }

    var fetchAttachmentFactory: Factory<FetchAttachment> {
        self {
            FetchAttachment(dependencies: .init(apiService: self.user.apiService))
        }
    }

    var userFactory: Factory<UserManager> {
        self {
            self.userManager
        }
    }

    init(userManager: UserManager, globalContainer: GlobalContainer) {
        self.userManager = userManager
        self.globalContainer = globalContainer

        manager.defaultScope = .shared
    }
}
