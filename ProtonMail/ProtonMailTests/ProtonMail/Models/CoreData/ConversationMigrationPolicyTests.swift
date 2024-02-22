// Copyright (c) 2022 Proton Technologies AG
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
import XCTest

final class ConversationMigrationPolicyTests: BaseMigrationTests {
    func testMigratingStores() throws {
        try migrateStore(fromVersionMOM: "2.0.10", toVersionMOM: "2.0.11")
        try migrateStore(fromVersionMOM: "2.0.9", toVersionMOM: "2.0.11")
        try migrateStore(fromVersionMOM: "2.0.8", toVersionMOM: "2.0.11")
        try migrateStore(fromVersionMOM: "2.0.7", toVersionMOM: "2.0.11")
        try migrateStore(fromVersionMOM: "2.0.6", toVersionMOM: "2.0.11")
        try migrateStore(fromVersionMOM: "2.0.5", toVersionMOM: "2.0.11")
        try migrateStore(fromVersionMOM: "2.0.4", toVersionMOM: "2.0.11")
        try migrateStore(fromVersionMOM: "2.0.3", toVersionMOM: "2.0.11")
        try migrateStore(fromVersionMOM: "2.0.2", toVersionMOM: "2.0.11")
        try migrateStore(fromVersionMOM: "2.0.1", toVersionMOM: "2.0.11")
        try migrateStore(fromVersionMOM: "2.0.0", toVersionMOM: "2.0.11")
    }
}
