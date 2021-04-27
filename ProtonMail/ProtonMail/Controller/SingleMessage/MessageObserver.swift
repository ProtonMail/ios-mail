//
//  MessageObserver.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

import CoreData

class MessageObserver: NSObject, NSFetchedResultsControllerDelegate {

    private let messageService: MessageDataService
    private let singleMessageFetchedController: NSFetchedResultsController<NSFetchRequestResult>?
    private var messageHasChanged: ((Message) -> Void)?

    init(messageId: String, messageService: MessageDataService) {
        self.messageService = messageService
        singleMessageFetchedController = messageService.fetchedMessageControllerForID(messageId)
    }

    func observe(messageHasChanged: @escaping (Message) -> Void) {
        self.messageHasChanged = messageHasChanged
        singleMessageFetchedController?.delegate = self
        try? singleMessageFetchedController?.performFetch()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let message = controller.fetchedObjects?.compactMap({ $0 as? Message }).first else { return }
        messageHasChanged?(message)
    }

}
