// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import CoreData
import Foundation
import ProtonCore_DataModel

/// This class is used to observe the message count of the location (LabelID == 12).
final class ScheduleSendLocationStatusObserver: NSObject, NSFetchedResultsControllerDelegate {
    private let context: NSManagedObjectContext
    private var countUpdate: ((Int) -> Void)?
    private var currentCount = 0
    private let userID: UserID
    private weak var viewModeDataSource: ViewModeDataSource?

    init?(contextProvider: CoreDataContextProviderProtocol,
          userID: UserID,
          viewModelDataSource: ViewModeDataSource,
          isEnable: Bool = UserInfo.isScheduleSendEnable) {
        guard isEnable else {
            return nil
        }
        self.context = contextProvider.mainContext
        self.userID = userID
        self.viewModeDataSource = viewModelDataSource
    }

    private lazy var fetchedController: NSFetchedResultsController<NSFetchRequestResult>? = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: LabelUpdate.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            LabelUpdate.Attributes.userID,
            userID.rawValue,
            LabelUpdate.Attributes.labelID,
            Message.Location.scheduled.rawValue
        )
        let sortDescriptor = NSSortDescriptor(key: LabelUpdate.Attributes.userID,
                                              ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: context,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()

    private lazy var conversationCountFetchedController: NSFetchedResultsController<NSFetchRequestResult>? = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ConversationCount.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            ConversationCount.Attributes.userID,
            userID.rawValue,
            ConversationCount.Attributes.labelID,
            Message.Location.scheduled.rawValue
        )
        let sortDescriptor = NSSortDescriptor(key: ConversationCount.Attributes.userID,
                                              ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: context,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()

    func observe(countUpdate: @escaping (Int) -> Void) -> Int {
        self.countUpdate = countUpdate

        fetchedController?.delegate = self
        try? fetchedController?.performFetch()

        conversationCountFetchedController?.delegate = self
        try? conversationCountFetchedController?.performFetch()

        guard let viewMode = viewModeDataSource?.getCurrentViewMode() else {
            return 0
        }

        switch viewMode {
        case .conversation:
            currentCount = Int(
                (conversationCountFetchedController?.fetchedObjects?.first as? ConversationCount)?.total ?? 0
            )
        case .singleMessage:
            currentCount = Int((fetchedController?.fetchedObjects?.first as? LabelUpdate)?.total ?? 0)
        }

        return currentCount
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let viewMode = viewModeDataSource?.getCurrentViewMode() else {
            return
        }

        var newValue: Int = 0
        switch viewMode {
        case .conversation:
            guard let labelUpdate = controller.fetchedObjects?.first as? ConversationCount else {
                return
            }
            newValue = max(Int(labelUpdate.total), 0)
        case .singleMessage:
            guard let labelUpdate = controller.fetchedObjects?.first as? LabelUpdate else {
                return
            }
            newValue = max(Int(labelUpdate.total), 0)
        }

        if currentCount != newValue {
            countUpdate?(newValue)
            currentCount = newValue
        }
    }
}
