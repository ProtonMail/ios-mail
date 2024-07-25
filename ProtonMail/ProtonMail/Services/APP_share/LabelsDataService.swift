//
//  LabelsDataService.swift
//  Proton Mail - Created on 8/13/15.
//
//
//  Copyright (c) 2019 Proton AG
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

import CoreData
import Foundation
import Groot
import PromiseKit
import ProtonCoreServices

enum LabelFetchType: Int {
    case all = 0
    case label = 1
    case folder = 2
    case contactGroup = 3
    case folderWithInbox = 4
    case folderWithOutbox = 5
}

// sourcery: mock
protocol LabelProviderProtocol: AnyObject {
    func makePublisher() -> LabelPublisherProtocol
    func getCustomFolders() -> [LabelEntity]
    func fetchV4Labels(completion: (@Sendable (Swift.Result<Void, Error>) -> Void)?)
}

extension LabelsDataService {
    enum LabelUpdateError: LocalizedError {
        case httpFailure

        var errorDescription: String? {
            LocalString._general_error_alert_title
        }
    }
}

class LabelsDataService {
    typealias Dependencies = AnyObject
    & LabelPublisher.Dependencies
    & HasAPIService
    & HasCacheService
    & HasConversationStateService
    & HasLastUpdatedStoreProtocol
    & HasUserDefaults

    private let userID: UserID
    private unowned let dependencies: Dependencies

    static let defaultFolderIDs: [String] = [
        Message.Location.inbox.rawValue,
        Message.Location.draft.rawValue,
        Message.HiddenLocation.draft.rawValue,
        Message.Location.sent.rawValue,
        Message.HiddenLocation.sent.rawValue,
        Message.Location.starred.rawValue,
        Message.Location.archive.rawValue,
        Message.Location.spam.rawValue,
        Message.Location.trash.rawValue,
        Message.Location.allmail.rawValue,
        Message.Location.scheduled.rawValue
    ]

    init(userID: UserID, dependencies: Dependencies) {
        self.dependencies = dependencies
        self.userID = userID
    }

    private func cleanLabelsAndFolders(except labelIDToPreserve: [String], context: NSManagedObjectContext) {
        let request = NSFetchRequest<Label>(entityName: Label.Attributes.entityName)
        request.predicate = NSPredicate(
            format: "%K == %@ AND (%K == 1 OR %K == 3) AND (NOT (%K IN %@))",
            Label.Attributes.userID,
            userID.rawValue,
            Label.Attributes.type,
            Label.Attributes.type,
            Label.Attributes.labelID,
            labelIDToPreserve
        )

        guard let labels = try? context.fetch(request) else {
            return
        }

        labels.forEach {
            context.delete($0)
        }
    }

    func cleanUp() {
        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            Label.delete(
                in: context,
                basedOn: NSPredicate(format: "%K == %@", Label.Attributes.userID, self.userID.rawValue)
            )

            ContextLabel.delete(
                in: context,
                basedOn: NSPredicate(format: "%K == %@", ContextLabel.Attributes.userID, self.userID.rawValue)
            )

                _ = context.saveUpstreamIfNeeded()
        }
    }

    @available(*, deprecated, message: "Prefer the async variant")
    func fetchV4Labels(completion: (@Sendable (Swift.Result<Void, Error>) -> Void)? = nil) {
        ConcurrencyUtils.runWithCompletion(block: fetchV4Labels, completion: completion)
    }

    /// Get label and folder through v4 api
    func fetchV4Labels() async throws {
        let labelReq = GetV4LabelsRequest(type: .label)
        let folderReq = GetV4LabelsRequest(type: .folder)

        async let labelsResponse = await dependencies.apiService.perform(request: labelReq, response: GetLabelsResponse())
        async let foldersResponse = await dependencies.apiService.perform(request: folderReq, response: GetLabelsResponse())

        let response = await [labelsResponse, foldersResponse]
        guard response.first(where: { $0.1.responseCode != 1000 }) == nil else {
            throw LabelUpdateError.httpFailure
        }

        let userLabelAndFolders = response
            .map(\.1)
            .compactMap(\.labels)
            .joined()
            .map {
                var label = $0
                label["UserID"] = userID.rawValue
                return label
            }

        let allFolders = userLabelAndFolders.appending(Self.defaultFolderIDs.map { ["ID": $0] })

        try dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            // to prevent deleted label won't be delete due to pull down to refresh
            let labelIDToPreserve = allFolders.compactMap { $0["ID"] as? String }
            self.cleanLabelsAndFolders(except: labelIDToPreserve, context: context)

            let results = try GRTJSONSerialization.objects(
                withEntityName: Label.Attributes.entityName,
                fromJSONArray: allFolders,
                in: context
            )

            let error = context.saveUpstreamIfNeeded()

            if results.count != allFolders.count {
                SystemLogger.log(message: "fetchV4Labels: data count does not match.", category: .menuDebug)
            }

            if let error = error {
                throw error
            }
        }
    }

    func fetchV4ContactGroup() -> Promise<Void> {
        return Promise { seal in
            let groupRes = GetV4LabelsRequest(type: .contactGroup)
            self.dependencies.apiService.perform(request: groupRes, response: GetLabelsResponse()) { _, res in
                if let error = res.error {
                    seal.reject(error)
                    return
                }
                guard var labels = res.labels else {
                    let error = NSError(domain: "", code: -1,
                                        localizedDescription: LocalString._error_no_object)
                    seal.reject(error)
                    return
                }
                for (index, _) in labels.enumerated() {
                    labels[index]["UserID"] = self.userID.rawValue
                }
                // save
                self.dependencies.contextProvider.performOnRootSavingContext { context in
                    do {
                        _ = try GRTJSONSerialization.objects(withEntityName: Label.Attributes.entityName, fromJSONArray: labels, in: context)
                        let error = context.saveUpstreamIfNeeded()
                        if error == nil {
                            seal.fulfill_()
                        } else {
                            seal.reject(error!)
                        }
                    } catch let ex as NSError {
                        seal.reject(ex)
                    }
                }
            }
        }
    }

    func getMenuFolderLabels() -> [MenuLabel] {
        let labels = self.getAllLabels(of: .all)
        let datas: [MenuLabel] = Array(labels: labels, previousRawData: [])
        let (_, folderItems) = datas.sortoutData()
        return folderItems
    }

    func getAllLabels(of type: LabelFetchType, context: NSManagedObjectContext) -> [Label] {
        let fetchRequest = NSFetchRequest<Label>(entityName: Label.Attributes.entityName)

        if type == .contactGroup, dependencies.userDefaults[.isCombineContactOn] {
            // in contact group searching, predicate must be consistent with this one
            fetchRequest.predicate = NSPredicate(format: "(%K == 2)", Label.Attributes.type)
        } else {
            fetchRequest.predicate = self.fetchRequestPredicate(type)
        }

        let context = context
        do {
            return try context.fetch(fetchRequest)
        } catch {
            assertionFailure("\(error)")
            return []
        }
    }

    func getAllLabels(of type: LabelFetchType) -> [LabelEntity] {
        dependencies.contextProvider.read { context in
            let labels = getAllLabels(of: type, context: context)
            return labels.map(LabelEntity.init(label:))
        }
    }

    func makePublisher() -> LabelPublisherProtocol {
        let params = LabelPublisher.Parameters(userID: userID)
        return LabelPublisher(parameters: params, dependencies: dependencies)
    }

    func fetchLabels(type: LabelFetchType) throws -> [LabelEntity] {
        return try dependencies.contextProvider.read { context in
            let request = NSFetchRequest<Label>(entityName: Label.Attributes.entityName)
            request.predicate = fetchRequestPredicate(type)
            if type != .contactGroup {
                request.sortDescriptors = [NSSortDescriptor(key: Label.Attributes.order, ascending: true)]
            } else {
                let strComp = NSSortDescriptor(key: Label.Attributes.name,
                                               ascending: true,
                                               selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
                request.sortDescriptors = [strComp]
            }
            let result = try context.fetch(request)
            return result.map(LabelEntity.init)
        }
    }

    private func fetchRequestPredicate(_ type: LabelFetchType) -> NSPredicate {
        switch type {
        case .all:
            return NSPredicate(format: "(labelID MATCHES %@) AND ((%K == 1) OR (%K == 3)) AND (%K == %@)", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.type, Label.Attributes.userID, self.userID.rawValue)
        case .folder:
            return NSPredicate(format: "(labelID MATCHES %@) AND (%K == 3) AND (%K == %@)", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.userID, self.userID.rawValue)
        case .folderWithInbox:
            // 0 - inbox, 6 - archive, 3 - trash, 4 - spam
            let defaults = NSPredicate(format: "labelID IN %@", [0, 6, 3, 4])
            // custom folders like in previous (LabelFetchType.folder) case
            let folder = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 3) AND (%K == %@)", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.userID, self.userID.rawValue)

            return NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, folder])
        case .folderWithOutbox:
            // 7 - sent, 6 - archive, 3 - trash
            let defaults = NSPredicate(format: "labelID IN %@", [6, 7, 3])
            // custom folders like in previous (LabelFetchType.folder) case
            let folder = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 3) AND (%K == %@)", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.userID, self.userID.rawValue)

            return NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, folder])
        case .label:
            return NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == %@)", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.userID, self.userID.rawValue)
        case .contactGroup:
            return NSPredicate(format: "(%K == 2) AND (%K == %@) AND (%K == 0)", Label.Attributes.type, Label.Attributes.userID, self.userID.rawValue, Label.Attributes.isSoftDeleted)
        }
    }

    func addNewLabel(_ response: [String: Any]?) {
        if var label = response {
            dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
                do {
                    label["UserID"] = self.userID.rawValue
                    try GRTJSONSerialization.object(withEntityName: Label.Attributes.entityName, fromJSONDictionary: label, in: context)
                    _ = context.saveUpstreamIfNeeded()
                } catch {}
            }
        }
    }

    func label(by labelID: LabelID) -> LabelEntity? {
        dependencies.contextProvider.read { context in
            if let label = Label.labelForLabelID(labelID.rawValue, inManagedObjectContext: context) {
                return LabelEntity(label: label)
            } else {
                return nil
            }
        }
    }

    func label(name: String) -> LabelEntity? {
        dependencies.contextProvider.read { context in
            if let label = Label.labelForLabelName(name, inManagedObjectContext: context) {
                return LabelEntity(label: label)
            } else {
                return nil
            }
        }
    }

    func unreadCount(by labelID: LabelID) -> Int {
        let viewMode = dependencies.conversationStateService.viewMode
        return dependencies.lastUpdatedStore.unreadCount(by: labelID, userID: self.userID, type: viewMode)
    }

    func getUnreadCounts(by labelIDs: [LabelID]) -> [String: Int] {
        let viewMode = dependencies.conversationStateService.viewMode
        return dependencies.lastUpdatedStore.getUnreadCounts(by: labelIDs, userID: self.userID, type: viewMode)
    }

    func resetCounter(labelID: LabelID)
    {
        dependencies.lastUpdatedStore.resetCounter(labelID: labelID, userID: userID)
    }

    func createNewLabel(name: String,
                        color: String,
                        type: PMLabelType = .label,
                        parentID: LabelID? = nil,
                        notify: Bool = true,
                        objectID: String? = nil,
                        completion: ((String?, NSError?) -> Void)?)
    {
        let route = CreateLabelRequest(name: name,
                                       color: color,
                                       type: type,
                                       parentID: parentID?.rawValue,
                                       notify: notify,
                                       expanded: true)
        dependencies.apiService.perform(request: route, response: CreateLabelRequestResponse()) { _, response in
            if let err = response.error {
                completion?(nil, err.toNSError)
            } else {
                let ID = response.label?["ID"] as? String
                let objectID = objectID ?? ""
                if let labelResponse = response.label {
                    self.dependencies.cacheService.addNewLabel(serverResponse: labelResponse, objectID: objectID, completion: nil)
                }
                completion?(ID, nil)
            }
        }
    }

    func updateLabel(_ label: LabelEntity,
                     name: String,
                     color: String,
                     parentID: LabelID?,
                     notify: Bool, completion: ((NSError?) -> Void)?)
    {
        let api = UpdateLabelRequest(id: label.labelID.rawValue,
                                     name: name,
                                     color: color,
                                     parentID: parentID?.rawValue,
                                     notify: notify)
        dependencies.apiService.perform(request: api, response: UpdateLabelRequestResponse()) { _, response in
            if let err = response.error {
                completion?(err.toNSError)
            } else {
                guard let labelDic = response.label else {
                    let error = NSError(domain: "", code: -1,
                                        localizedDescription: LocalString._error_no_object)
                    completion?(error)
                    return
                }
                self.dependencies.cacheService.updateLabel(serverReponse: labelDic) {
                    completion?(nil)
                }
            }
        }
    }

    /// Send api to delete label and remove related labels from the DB
    /// - Parameters:
    ///   - label: The label want to be deleted
    ///   - subLabelIDs: Object ids array of child labels
    ///   - completion: completion
    func deleteLabel(_ label: LabelEntity,
                     subLabels: [LabelEntity] = [],
                     completion: (() -> Void)?)
    {
        let api = DeleteLabelRequest(lable_id: label.labelID.rawValue)
        dependencies.apiService.perform(request: api, response: VoidResponse()) { _, _ in
        }
        let ids = subLabels.map{$0.objectID.rawValue} + [label.objectID.rawValue]
        dependencies.cacheService.deleteLabels(objectIDs: ids) {
            completion?()
        }
    }
}

extension LabelsDataService: LabelProviderProtocol {
    func getCustomFolders() -> [LabelEntity] {
        getAllLabels(of: .folder)
    }
}
