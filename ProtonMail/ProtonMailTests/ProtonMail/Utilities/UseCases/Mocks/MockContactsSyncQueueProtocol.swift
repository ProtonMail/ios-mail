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

import ProtonCoreTestingToolkit
import Combine
@testable import ProtonMail

class MockContactsSyncQueueProtocol: ContactsSyncQueueProtocol {
    @PropertyStub(\MockContactsSyncQueueProtocol.progressPublisher, initialGet: CurrentValueSubject<ContactsSyncQueue.Progress, Never>(ContactsSyncQueue.Progress())) var progressPublisherStub
    var progressPublisher: CurrentValueSubject<ContactsSyncQueue.Progress, Never> {
        progressPublisherStub()
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

    @FuncStub(MockContactsSyncQueueProtocol.deleteQueue) var deleteQueueStub
    func deleteQueue() {
        deleteQueueStub()
    }

}
