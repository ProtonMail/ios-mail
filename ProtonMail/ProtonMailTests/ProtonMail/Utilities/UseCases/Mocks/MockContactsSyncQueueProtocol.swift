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

import ProtonCoreTestingToolkitUnitTestsCore
import Combine
@testable import ProtonMail

class MockContactsSyncQueueProtocol: ContactsSyncQueueProtocol {
    var progressPublisher: AnyPublisher<ContactsSyncQueue.Progress, Never> {
        _progressPublisher.eraseToAnyPublisher()
    }
    var _progressPublisher: PassthroughSubject<ContactsSyncQueue.Progress, Never> = .init()

    var protonStorageQuotaExceeded: AnyPublisher<Void, Never> {
        _protonStorageQuotaExceeded.eraseToAnyPublisher()
    }
    var _protonStorageQuotaExceeded: PassthroughSubject<Void, Never> = .init()

    @FuncStub(MockContactsSyncQueueProtocol.setup) var setupStub
    func setup() {
        setupStub()
    }

    @FuncStub(MockContactsSyncQueueProtocol.start) var startStub
    func start() {
        startStub()
    }

    @FuncStub(MockContactsSyncQueueProtocol.pause) var pauseStub
    func pause() {
        pauseStub()
    }

    @FuncStub(MockContactsSyncQueueProtocol.resume) var resumeStub
    func resume() {
        resumeStub()
    }

    @FuncStub(MockContactsSyncQueueProtocol.addTask) var addTaskStub
    func addTask(_ task: ContactTask) {
        addTaskStub(task)
    }

    @FuncStub(MockContactsSyncQueueProtocol.saveQueueToDisk) var saveQueueToDiskStub
    func saveQueueToDisk() {
        saveQueueToDiskStub()
    }

    @FuncStub(MockContactsSyncQueueProtocol.deleteQueue) var deleteQueueStub
    func deleteQueue() {
        deleteQueueStub()
    }

}
