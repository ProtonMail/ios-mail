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

import AwaitKit
import CoreData
import Foundation
import Groot
import PromiseKit
import ProtonCore_Services

enum LabelFetchType: Int {
    case all = 0
    case label = 1
    case folder = 2
    case contactGroup = 3
    case folderWithInbox = 4
    case folderWithOutbox = 5
}

protocol LabelProviderProtocol: AnyObject {
    func makePublisher() -> LabelPublisherProtocol
    func getCustomFolders() -> [Label]
    func getLabel(by labelID: LabelID) -> Label?
    func fetchV4Labels() -> Promise<Void>
}

class LabelsDataService: Service, HasLocalStorage {
    let apiService: APIService
    private let userID: UserID
    private let contextProvider: CoreDataContextProviderProtocol
    private let lastUpdatedStore: LastUpdatedStoreProtocol
    private let cacheService: CacheService
    weak var viewModeDataSource: ViewModeDataSource?

    init(api: APIService,
         userID: UserID,
         contextProvider: CoreDataContextProviderProtocol,
         lastUpdatedStore: LastUpdatedStoreProtocol,
         cacheService: CacheService)
    {
        self.apiService = api
        self.userID = userID
        self.contextProvider = contextProvider
        self.lastUpdatedStore = lastUpdatedStore
        self.cacheService = cacheService
    }

    func cleanUp() -> Promise<Void> {
        return Promise { seal in
            let labelFetch = NSFetchRequest<Label>(entityName: Label.Attributes.entityName)
            labelFetch.predicate = NSPredicate(format: "%K == %@", Label.Attributes.userID, self.userID.rawValue)

            let contextLabelRequest = NSFetchRequest<ContextLabel>(entityName: ContextLabel.Attributes.entityName)
            contextLabelRequest.predicate = NSPredicate(format: "%K == %@", ContextLabel.Attributes.userID, self.userID.rawValue)

            let context = self.contextProvider.rootSavingContext
            context.perform {
                if let labelResults = try? context.fetch(labelFetch) {
                    labelResults.forEach(context.delete)
                }

                if let contextResults = try? context.fetch(contextLabelRequest) {
                    contextResults.forEach(context.delete)
                }
                _ = context.saveUpstreamIfNeeded()
                seal.fulfill_()
            }
        }
    }

    static func cleanUpAll() -> Promise<Void> {
        return Promise { seal in
            let coreDataService = sharedServices.get(by: CoreDataService.self)
            let context = coreDataService.operationContext
            coreDataService.enqueue(context: context) { context in
                Label.deleteAll(inContext: context)
                LabelUpdate.deleteAll(inContext: context)
                ContextLabel.deleteAll(inContext: context)
                seal.fulfill_()
            }
        }
    }

    /// Get label and folder through v4 api
    func fetchV4Labels() -> Promise<Void> {
        return Promise { seal in
            async {
                let labelsResponse = GetLabelsResponse()
                let foldersResponse = GetLabelsResponse()

                let group = DispatchGroup()
                group.enter()
                self.apiService.exec(route: GetV4LabelsRequest(type: .label), responseObject: labelsResponse) { _, _ in
                    group.leave()
                }
                group.enter()
                self.apiService.exec(route: GetV4LabelsRequest(type: .folder), responseObject: foldersResponse) { _, _ in
                    group.leave()
                }
                group.wait()

                if let error = labelsResponse.error {
                    seal.reject(error)
                    return
                }
                if let error = foldersResponse.error {
                    seal.reject(error)
                    return
                }

                guard var labels = labelsResponse.labels,
                      var folders = foldersResponse.labels
                else {
                    let error = NSError(domain: "", code: -1,
                                        localizedDescription: LocalString._error_no_object)
                    seal.reject(error)
                    return
                }
                for (index, _) in labels.enumerated() {
                    labels[index]["UserID"] = self.userID.rawValue
                }
                for (index, _) in folders.enumerated() {
                    folders[index]["UserID"] = self.userID.rawValue
                }

                folders.append(["ID": "0"]) // case inbox   = "0"
                folders.append(["ID": "8"]) // case draft   = "8"
                folders.append(["ID": "1"]) // case draft   = "1"
                folders.append(["ID": "7"]) // case sent    = "7"
                folders.append(["ID": "2"]) // case sent    = "2"
                folders.append(["ID": "10"]) // case starred = "10"
                folders.append(["ID": "6"]) // case archive = "6"
                folders.append(["ID": "4"]) // case spam    = "4"
                folders.append(["ID": "3"]) // case trash   = "3"
                folders.append(["ID": "5"]) // case allmail = "5"

                let allFolders = labels + folders
                self.cleanUp().cauterize()

                // save
                let context = self.contextProvider.rootSavingContext
                context.perform {
                    do {
                        _ = try GRTJSONSerialization.objects(withEntityName: Label.Attributes.entityName, fromJSONArray: allFolders, in: context)
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

    func fetchV4ContactGroup() -> Promise<Void> {
        return Promise { seal in
            let groupRes = GetV4LabelsRequest(type: .contactGroup)
            self.apiService.exec(route: groupRes, responseObject: GetLabelsResponse()) { (_, res) in
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
                let context = self.contextProvider.rootSavingContext
                context.perform {
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
        let labels = self.getAllLabels(of: .all, context: self.contextProvider.mainContext).compactMap { LabelEntity(label: $0) }
        let datas: [MenuLabel] = Array(labels: labels, previousRawData: [])
        let (_, folderItems) = datas.sortoutData()
        return folderItems
    }

    func getAllLabels(of type: LabelFetchType, context: NSManagedObjectContext) -> [Label] {
        let fetchRequest = NSFetchRequest<Label>(entityName: Label.Attributes.entityName)

        if type == .contactGroup, userCachedStatus.isCombineContactOn {
            // in contact group searching, predicate must be consistent with this one
            fetchRequest.predicate = NSPredicate(format: "(%K == 2)", Label.Attributes.type)
        } else {
            fetchRequest.predicate = self.fetchRequestPrecidate(type)
        }

        let context = context
        do {
            return try context.fetch(fetchRequest)
        } catch {}

        return []
    }

    func makePublisher() -> LabelPublisherProtocol {
        let params = LabelPublisher.Parameters(userID: userID)
        return LabelPublisher(parameters: params)
    }

    func fetchedResultsController(_ type: LabelFetchType) -> NSFetchedResultsController<Label> {
        let moc = self.contextProvider.mainContext
        let fetchRequest = NSFetchRequest<Label>(entityName: Label.Attributes.entityName)
        fetchRequest.predicate = self.fetchRequestPrecidate(type)

        if type != .contactGroup {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Label.Attributes.order, ascending: true)]
        } else {
            let strComp = NSSortDescriptor(key: Label.Attributes.name,
                                           ascending: true,
                                           selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            fetchRequest.sortDescriptors = [strComp]
        }
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
    }

    private func fetchRequestPrecidate(_ type: LabelFetchType) -> NSPredicate {
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
            let context = self.contextProvider.rootSavingContext
            context.performAndWait {
                do {
                    label["UserID"] = self.userID.rawValue
                    try GRTJSONSerialization.object(withEntityName: Label.Attributes.entityName, fromJSONDictionary: label, in: context)
                    _ = context.saveUpstreamIfNeeded()
                } catch {}
            }
        }
    }

    func labelFetchedController(by labelID: LabelID) -> NSFetchedResultsController<Label> {
        let context = self.contextProvider.mainContext
        return Label.labelFetchController(for: labelID.rawValue, inManagedObjectContext: context)
    }

    func label(by labelID: LabelID) -> Label? {
        let context = self.contextProvider.mainContext
        return Label.labelForLabelID(labelID.rawValue, inManagedObjectContext: context)
    }

    func label(name: String) -> Label? {
        let context = self.contextProvider.mainContext
        return Label.labelForLabelName(name, inManagedObjectContext: context)
    }

    func lastUpdate(by labelID: LabelID, userID: String? = nil) -> LabelCountEntity? {
        guard let viewMode = self.viewModeDataSource?.getCurrentViewMode() else {
            return nil
        }

        let id = userID ?? self.userID.rawValue
        return self.lastUpdatedStore.lastUpdate(by: labelID.rawValue, userID: id, type: viewMode)
    }
    
    func unreadCount(by labelID: LabelID) -> Int {
        guard let viewMode = self.viewModeDataSource?.getCurrentViewMode() else {
            return 0
        }
        return lastUpdatedStore.unreadCount(by: labelID.rawValue, userID: self.userID.rawValue, type: viewMode)
    }

    func getUnreadCounts(by labelIDs: [LabelID], completion: @escaping ([String: Int]) -> Void) {
        guard let viewMode = self.viewModeDataSource?.getCurrentViewMode() else {
            return completion([:])
        }

        lastUpdatedStore.getUnreadCounts(by: labelIDs.map(\.rawValue), userID: self.userID.rawValue, type: viewMode, completion: completion)
    }

    func resetCounter(labelID: LabelID,
                      userID: String? = nil,
                      viewMode: ViewMode? = nil)
    {
        let id = userID ?? self.userID.rawValue
        self.lastUpdatedStore.resetCounter(labelID: labelID.rawValue, userID: id, type: viewMode)
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
        self.apiService.exec(route: route, responseObject: CreateLabelRequestResponse()) { (task, response) in
            if let err = response.error {
                completion?(nil, err.toNSError)
            } else {
                let ID = response.label?["ID"] as? String
                let objectID = objectID ?? ""
                if let labelResponse = response.label {
                    self.cacheService.addNewLabel(serverResponse: labelResponse, objectID: objectID, completion: nil)
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
        self.apiService.exec(route: api, responseObject: UpdateLabelRequestResponse()) { (task, response) in
            if let err = response.error {
                completion?(err.toNSError)
            } else {
                guard let labelDic = response.label else {
                    let error = NSError(domain: "", code: -1,
                                        localizedDescription: LocalString._error_no_object)
                    completion?(error)
                    return
                }
                self.cacheService.updateLabel(serverReponse: labelDic) {
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
        self.apiService.exec(route: api, responseObject: VoidResponse()) { (_, _) in
        }
        let ids = subLabels.map{$0.objectID.rawValue} + [label.objectID.rawValue]
        self.cacheService.deleteLabels(objectIDs: ids) {
            completion?()
        }
    }
}

extension LabelsDataService: LabelProviderProtocol {
    func getCustomFolders() -> [Label] {
        return getAllLabels(of: .folder, context: contextProvider.mainContext)
    }

    func getLabel(by labelID: LabelID) -> Label? {
        return label(by: labelID)
    }
}
